/// The booking control model: three independent state machines and the rules
/// that bind them.
///
/// A booking carries **three** states that are genuinely separate concerns and
/// were previously rendered as three unrelated chips, leaving the operator to
/// infer what to do:
///
///  - **Booking state** (`operation_bookings.status`) — does this passenger hold
///    a seat, and how far through the journey are they?
///  - **Payment state** (`operation_bookings.payment_status`, mirrored in
///    `booking_payments.status`) — has the office been paid, and is the money
///    still reversible?
///  - **Operational trip state** (`operation_trips.status`) — has the vehicle
///    left? This one belongs to the trip, not the booking, but it constrains
///    what may still be done to the booking.
///
/// This file defines the legal moves within each machine, the combinations that
/// are contradictory *across* machines, and — the part an operator actually
/// wants — the single next action the desk should take.
///
/// The database is the enforcement authority (`approve_payment` refuses a
/// booking that is not `reserved`, refuses one with no submitted payment, and
/// updates seat/passenger/notification rows in the same transaction). This model
/// exists so the **UI can explain and pre-empt** those refusals rather than
/// surfacing `booking_not_pending` from a failed RPC.
library;

import 'operation_booking.dart';

extension BookingStatusRules on BookingStatus {
  /// Whether [next] is a legal booking-state move.
  ///
  /// Forward-only along the journey, with cancellation available until the
  /// passenger has actually travelled. `boarded → reserved` is not a state, and
  /// resurrecting a cancelled booking is a *new* booking, not a transition —
  /// the released seat may already belong to someone else.
  bool canTransitionTo(BookingStatus next) => switch (this) {
    BookingStatus.draft =>
      next == BookingStatus.reserved || next == BookingStatus.cancelled,
    BookingStatus.reserved =>
      next == BookingStatus.confirmed || next == BookingStatus.cancelled,
    BookingStatus.confirmed =>
      next == BookingStatus.boarded || next == BookingStatus.cancelled,

    BookingStatus.boarded => next == BookingStatus.completed,
    BookingStatus.completed || BookingStatus.cancelled => false,
  };

  /// Terminal states — the booking has left the working set.
  bool get isClosed =>
      this == BookingStatus.completed || this == BookingStatus.cancelled;

  /// The passenger holds (or held) a seat that occupies capacity.
  bool get holdsSeat =>
      this == BookingStatus.reserved ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.boarded;

  /// The passenger has physically travelled. Money is no longer trivially
  /// refundable and the seat cannot be released.
  bool get hasTravelled =>
      this == BookingStatus.boarded || this == BookingStatus.completed;
}

extension PaymentStatusRules on PaymentStatus {
  /// Whether [next] is a legal payment-state move.
  ///
  /// `rejected` deliberately returns to `submitted`: a passenger whose receipt
  /// was unreadable uploads a better one, and that must not require a new
  /// booking. `approved` may only move to `refunded` — money that has been
  /// taken is reversed, never un-approved.
  bool canTransitionTo(PaymentStatus next) => switch (this) {
    PaymentStatus.pending =>
      next == PaymentStatus.submitted ||
          next == PaymentStatus.failed ||
          next == PaymentStatus.cancelled,
    PaymentStatus.submitted =>
      next == PaymentStatus.underReview ||
          next == PaymentStatus.approved ||
          next == PaymentStatus.rejected ||
          next == PaymentStatus.cancelled,
    PaymentStatus.underReview =>
      next == PaymentStatus.approved ||
          next == PaymentStatus.rejected ||
          next == PaymentStatus.cancelled,

    PaymentStatus.rejected =>
      next == PaymentStatus.submitted || next == PaymentStatus.cancelled,
    PaymentStatus.approved => next == PaymentStatus.refunded,
    PaymentStatus.failed =>
      next == PaymentStatus.submitted || next == PaymentStatus.cancelled,
    PaymentStatus.refunded || PaymentStatus.cancelled => false,
  };

  /// The office has the money.
  bool get isSettled => this == PaymentStatus.approved;

  /// Awaiting a decision from the desk — the actionable review queue.
  bool get needsReview =>
      this == PaymentStatus.submitted || this == PaymentStatus.underReview;

  /// No money will arrive on this booking without further passenger action.
  bool get isUnsettled =>
      this == PaymentStatus.pending ||
      this == PaymentStatus.rejected ||
      this == PaymentStatus.failed;

  /// Terminal — nothing further will happen to this payment.
  bool get isClosed =>
      this == PaymentStatus.refunded || this == PaymentStatus.cancelled;
}

extension BookingReviewRules on OperationBooking {
  /// Whether the desk can actually decide this payment right now.
  ///
  /// [OperationBooking.awaitingReview] reads the *payment* machine alone, and
  /// the board was offering قبول / رفض / إعادة رفع off it — so a **cancelled**
  /// booking whose receipt happened to be uploaded still showed three enabled
  /// review buttons. Pressing one is a guaranteed round trip to a server
  /// refusal: `approve_payment` requires the booking to be `reserved` and
  /// answers `booking_not_pending` otherwise. Pre-empting that refusal instead
  /// of surfacing it is the entire point of this file.
  bool get canReviewPayment => awaitingReview && !status.isClosed;
}

/// How serious a detected inconsistency is.
enum BookingIssueSeverity {
  /// Money or seat integrity is wrong. Someone must act.
  critical,

  /// Legal but unusual — worth an operator's eye, not an alarm.
  warning,
}

/// A contradiction between a booking's state and its payment state.
///
/// These are *detections*, not exceptions: the rows already exist in the
/// database, and refusing to render them would simply hide the problem. The
/// desk needs to see them, which is what this type is for.
class BookingIssue {
  final String code;
  final String message;
  final BookingIssueSeverity severity;

  const BookingIssue({
    required this.code,
    required this.message,
    required this.severity,
  });
}

/// Combinations of booking state and payment state that must never coexist.
///
/// Each rule names a real operational failure, not a theoretical one:
///
///  - **paid-but-cancelled** — the office is holding a passenger's money for a
///    seat that was released. Egypt's cash-heavy market makes this the single
///    most common source of disputes.
///  - **confirmed-without-payment** — a seat is committed and blocking capacity
///    with nothing collected. `approve_payment` makes this impossible going
///    forward, but historical rows and direct writes can still produce it.
///  - **travelled-without-payment** — the passenger rode for free.
///  - **completed-with-refund** — the journey happened and the money went back;
///    legal (a service failure) but it must be visible, not silent.
List<BookingIssue> detectBookingIssues({
  required BookingStatus status,
  required PaymentStatus paymentStatus,
}) {
  final issues = <BookingIssue>[];

  if (status == BookingStatus.cancelled && paymentStatus.isSettled) {
    issues.add(
      const BookingIssue(
        code: 'paid_but_cancelled',
        message:
            'الحجز ملغى بينما الدفع معتمد — المبلغ ما زال لدى المكتب ولم يُرد للعميل.',
        severity: BookingIssueSeverity.critical,
      ),
    );
  }

  if (status == BookingStatus.confirmed && !paymentStatus.isSettled) {
    issues.add(
      const BookingIssue(
        code: 'confirmed_without_payment',
        message: 'الحجز مؤكد بينما الدفع غير معتمد — المقعد محجوز دون تحصيل.',
        severity: BookingIssueSeverity.critical,
      ),
    );
  }

  if (status.hasTravelled && paymentStatus.isUnsettled) {
    issues.add(
      const BookingIssue(
        code: 'travelled_without_payment',
        message: 'الراكب سافر دون اعتماد الدفع — يلزم تحصيل أو تسوية.',
        severity: BookingIssueSeverity.critical,
      ),
    );
  }

  if (status == BookingStatus.completed &&
      paymentStatus == PaymentStatus.refunded) {
    issues.add(
      const BookingIssue(
        code: 'completed_but_refunded',
        message: 'الرحلة اكتملت وتم رد المبلغ — تأكد من وجود سبب موثّق.',
        severity: BookingIssueSeverity.warning,
      ),
    );
  }

  return issues;
}

/// What the desk can do with a booking right now.
enum BookingActionKind {
  approvePayment,
  rejectPayment,
  requestReview,
  reassign,
  cancel,
  resolveContradiction,

  /// Nothing to do — the booking is closed or is waiting on the passenger.
  none,
}

/// The single most useful thing an operator can do with this booking, plus the
/// reason — so the UI states an instruction instead of two status chips the
/// operator has to interpret.
class BookingNextAction {
  final BookingActionKind kind;

  /// Imperative label for the primary control.
  final String label;

  /// Why this is the next step, or why nothing can be done.
  final String reason;

  const BookingNextAction({
    required this.kind,
    required this.label,
    required this.reason,
  });

  bool get isActionable => kind != BookingActionKind.none;
}

/// Resolves the next action for a booking.
///
/// Order matters: a contradiction outranks routine work, because acting on a
/// booking whose money and seat disagree makes the disagreement worse. After
/// that, an awaiting-review payment is the desk's real queue. Everything else is
/// waiting on the passenger or already finished.
BookingNextAction resolveNextAction({
  required BookingStatus status,
  required PaymentStatus paymentStatus,
  required bool hasReceipt,
}) {
  final issues = detectBookingIssues(
    status: status,
    paymentStatus: paymentStatus,
  );
  final critical = issues
      .where((i) => i.severity == BookingIssueSeverity.critical)
      .toList();
  if (critical.isNotEmpty) {
    return BookingNextAction(
      kind: BookingActionKind.resolveContradiction,
      label: 'معالجة التعارض',
      reason: critical.first.message,
    );
  }

  if (status.isClosed) {
    return BookingNextAction(
      kind: BookingActionKind.none,
      label: 'لا إجراء',
      reason: status == BookingStatus.cancelled
          ? 'الحجز ملغى ولا يشغل مقعداً.'
          : 'الرحلة اكتملت وأُغلق الحجز.',
    );
  }

  if (paymentStatus.needsReview) {
    if (!hasReceipt) {
      return const BookingNextAction(
        kind: BookingActionKind.requestReview,
        label: 'طلب إيصال',
        reason: 'الدفع بانتظار المراجعة ولا يوجد إيصال مرفوع للاطلاع عليه.',
      );
    }
    return const BookingNextAction(
      kind: BookingActionKind.approvePayment,
      label: 'مراجعة الدفع',
      reason: 'إيصال مرفوع بانتظار قرار المكتب — اعتمده أو ارفضه بسبب واضح.',
    );
  }

  if (paymentStatus == PaymentStatus.rejected) {
    return const BookingNextAction(
      kind: BookingActionKind.none,
      label: 'بانتظار العميل',
      reason: 'تم رفض الإيصال — العميل بحاجة لرفع إيصال صحيح.',
    );
  }

  if (paymentStatus == PaymentStatus.pending) {
    return const BookingNextAction(
      kind: BookingActionKind.none,
      label: 'بانتظار العميل',
      reason: 'المقعد محجوز مؤقتاً بانتظار رفع العميل لإيصال الدفع.',
    );
  }

  if (status == BookingStatus.confirmed && paymentStatus.isSettled) {
    return const BookingNextAction(
      kind: BookingActionKind.none,
      label: 'جاهز للسفر',
      reason: 'الدفع معتمد والمقعد مؤكد — لا يلزم إجراء قبل الرحلة.',
    );
  }

  return const BookingNextAction(
    kind: BookingActionKind.none,
    label: 'لا إجراء',
    reason: 'لا يوجد إجراء مطلوب من المكتب في هذه الحالة.',
  );
}
