/// Finance is the money-intelligence module: it *reads* every pound that moved
/// and explains it. Verification of payment receipts (approve / reject / ask for
/// a re-upload) deliberately lives in the Bookings module only — an operator
/// must decide on a receipt where the booking context is, and a number here must
/// never be a button.
library;

import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';

enum FinancePaymentMethod {
  instapay('انستا باي'),
  vodafoneCash('فودافون كاش'),
  cash('نقدي'),
  card('بطاقة');

  final String label;
  const FinancePaymentMethod(this.label);
}

/// Money vocabulary, not workflow vocabulary: a finance reader cares whether an
/// amount was *collected*, is still *outstanding*, fell through, or went back.
enum PaymentStatus {
  success('محصّلة'),
  pending('قيد التحصيل'),
  cancelled('ملغاة'),
  refunded('مستردة');

  final String label;
  const PaymentStatus(this.label);
}

enum RefundStatus {
  pending('بانتظار الموافقة'),
  approved('تمت الموافقة'),
  rejected('مرفوض');

  final String label;
  const RefundStatus(this.label);
}

enum SubscriptionStatus {
  active('نشط'),
  expired('منتهي'),
  cancelled('ملغي'),
  pendingPayment('بانتظار الدفع');

  final String label;
  const SubscriptionStatus(this.label);
}

/// How a period's boundaries are worked out.
///
/// The distinction is not pedantry: on the 3rd of the month "هذا الشهر" and
/// "آخر ٣٠ يوم" differ by an order of magnitude, and an owner reconciling a
/// month means the calendar one while an owner watching momentum means the
/// rolling one. Conflating them is how a finance screen ends up arguing with
/// the paper the owner is holding.
enum FinancePeriodShape {
  /// A window of [FinancePeriod.days] days ending now, today included.
  rolling,

  /// A calendar month, [FinancePeriod.monthsBack] months before the current
  /// one. `0` is the month to date; `1` is the last complete month.
  calendar,

  /// No lower bound — every row the ledger holds.
  unbounded,

  /// Two dates the operator picked.
  custom,
}

/// The reporting window every figure on the screen is measured over. One
/// selection drives the KPIs, the charts, the ledger and the exported
/// statement, so two numbers on the same screen can never mean two periods.
enum FinancePeriod {
  today('اليوم', FinancePeriodShape.rolling, days: 1),
  week('آخر ٧ أيام', FinancePeriodShape.rolling, days: 7),
  thisMonth('هذا الشهر', FinancePeriodShape.calendar, monthsBack: 0),
  lastMonth('الشهر الماضي', FinancePeriodShape.calendar, monthsBack: 1),
  month('آخر ٣٠ يوم', FinancePeriodShape.rolling, days: 30),
  quarter('آخر ٩٠ يوم', FinancePeriodShape.rolling, days: 90),
  all('كل الفترات', FinancePeriodShape.unbounded),
  custom('فترة مخصصة', FinancePeriodShape.custom);

  final String label;
  final FinancePeriodShape shape;

  /// Window length in days, counting today. Only meaningful for
  /// [FinancePeriodShape.rolling].
  final int? days;

  /// How many calendar months back. Only meaningful for
  /// [FinancePeriodShape.calendar].
  final int monthsBack;

  const FinancePeriod(
    this.label,
    this.shape, {
    this.days,
    this.monthsBack = 0,
  });

  // Resolving a preset into concrete bounds is deliberately not a method here:
  // a custom range has no enum to hang its dates on, and two ways to answer
  // "when does this window start" is one too many. See [FinanceWindow.resolve].
}

/// A resolved reporting window: concrete bounds, the words that describe them,
/// and the comparable window before it.
///
/// Resolution lives here rather than on [FinancePeriod] because a custom range
/// has no enum to hang its dates on, and because "what does السابقة mean for
/// this period" is a different answer per shape — the month before a calendar
/// month, and an equally long span before a rolling one.
class FinanceWindow {
  final FinancePeriod period;

  /// First instant included, or `null` for an unbounded window.
  final DateTime? start;

  /// Last instant included.
  final DateTime end;

  /// What the period bar and every panel subtitle call this window.
  final String label;

  /// What the comparison column is measured against, in words. Shown next to
  /// every delta so a "+18%" can never be read against the wrong baseline.
  final String previousLabel;

  const FinanceWindow({
    required this.period,
    required this.start,
    required this.end,
    required this.label,
    required this.previousLabel,
  });

  FinanceDateRange get range => FinanceDateRange(start: start, end: end);

  bool get isBounded => start != null;

  /// True when the window's own end is in the past — a closed book rather than
  /// a period still filling up. The comparison means something different for
  /// each, and the UI says which.
  bool get isComplete => period.shape == FinancePeriodShape.calendar
      ? period.monthsBack > 0
      : false;

  static FinanceWindow resolve(
    FinancePeriod period,
    DateTime now, {
    FinanceDateRange? custom,
  }) {
    final today = DateTime(now.year, now.month, now.day);

    switch (period.shape) {
      case FinancePeriodShape.rolling:
        final length = period.days!;
        return FinanceWindow(
          period: period,
          start: _shiftDays(today, -(length - 1)),
          end: now,
          label: period.label,
          previousLabel: length == 1
              ? 'أمس'
              : 'الـ$length يوم السابقة',
        );

      case FinancePeriodShape.calendar:
        final anchor = _monthStart(now, monthsBack: period.monthsBack);
        final isCurrentMonth = period.monthsBack == 0;
        return FinanceWindow(
          period: period,
          start: anchor,
          
          end: isCurrentMonth ? now : _lastInstantOf(anchor),
          label: '${period.label} (${_monthName(anchor)})',
          previousLabel: isCurrentMonth
              ? 'نفس المدة من الشهر الماضي'
              : _monthName(_monthStart(anchor, monthsBack: 1)),
        );

      case FinancePeriodShape.unbounded:
        return FinanceWindow(
          period: period,
          start: null,
          end: now,
          label: period.label,
          previousLabel: '—',
        );

      case FinancePeriodShape.custom:
        final range = custom;
        
        if (range == null || range.start == null) {
          return FinanceWindow.resolve(FinancePeriod.month, now);
        }
        return FinanceWindow(
          period: period,
          start: range.start,
          end: range.end,
          label: '${_day(range.start!)} — ${_day(range.end)}',
          previousLabel: 'الفترة المماثلة السابقة',
        );
    }
  }

  /// The window this one's deltas are measured against, or `null` when there is
  /// nothing comparable — dividing by a window that does not exist prints an
  /// impressive but meaningless number.
  FinanceWindow? get previous {
    switch (period.shape) {
      case FinancePeriodShape.unbounded:
        return null;

      case FinancePeriodShape.calendar:
        final anchor = start!;
        final previousStart = _monthStart(anchor, monthsBack: 1);
        
        final span = end.difference(anchor);
        final previousEnd = period.monthsBack == 0
            ? _min(previousStart.add(span), _lastInstantOf(previousStart))
            : _lastInstantOf(previousStart);
        return FinanceWindow(
          period: period,
          start: previousStart,
          end: previousEnd,
          label: _monthName(previousStart),
          previousLabel: '—',
        );

      case FinancePeriodShape.rolling:
      case FinancePeriodShape.custom:
        final from = start;
        if (from == null) return null;

        // The whole window shifted back by its own length in days, keeping the
        // same time of day at both ends.
        //
        // The obvious alternative — end the previous window one microsecond
        // before this one starts — compares a *partial* window against a
        // *complete* one: at 3pm "اليوم" holds fifteen hours and would be
        // measured against the whole of yesterday, reporting a collapse every
        // afternoon. Shifting keeps both windows the same shape. The cost is a
        // few hours between them that belong to neither, which is the standard
        // "same period last week" reading and the one an owner expects.
        final length = period.shape == FinancePeriodShape.rolling
            ? period.days!
            : end.difference(from).inDays + 1;
        return FinanceWindow(
          period: period,
          start: _shiftDays(from, -length),
          end: _shiftDays(end, -length),
          label: previousLabel,
          previousLabel: '—',
        );
    }
  }

  /// Calendar arithmetic rather than `Duration(days:)`: Egypt observes summer
  /// time, and a 30-day `Duration` across a transition lands an hour off, which
  /// is enough to move a midnight booking into the wrong window.
  static DateTime _shiftDays(DateTime from, int days) => DateTime(
    from.year,
    from.month,
    from.day + days,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
    from.microsecond,
  );

  static DateTime _monthStart(DateTime from, {required int monthsBack}) {
    final month = from.month - monthsBack;
    return DateTime(from.year, month, 1);
  }

  /// Last representable instant of [monthStart]'s month.
  static DateTime _lastInstantOf(DateTime monthStart) => DateTime(
    monthStart.year,
    monthStart.month + 1,
    1,
  ).subtract(const Duration(microseconds: 1));

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  static const _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static String _monthName(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  static String _day(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Which side of the business a money movement came from.
enum FinanceEntryType {
  booking('حجز رحلة', 'الحجوزات'),
  subscription('اشتراك باقة', 'الاشتراكات');

  final String label;
  final String pluralLabel;
  const FinanceEntryType(this.label, this.pluralLabel);
}

/// Half-open reporting window `[start, end]` used by the analytics layer.
/// Hand-rolled instead of `DateTimeRange` so the domain stays pure Dart.
class FinanceDateRange {
  final DateTime? start;
  final DateTime end;

  const FinanceDateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    if (date.isAfter(end)) return false;
    final from = start;
    return from == null || !date.isBefore(from);
  }
}

/// Where a booking's *seat* stands, collapsed to what a money reader needs.
///
/// The bookings module owns the full six-state machine; Finance only ever asks
/// three questions of it — is this fare still expected, has it been earned, or
/// has the seat gone away. Collapsing here rather than importing the bookings
/// entity keeps the two modules' vocabularies from fusing while still letting
/// Finance stop counting money nobody is waiting for.
enum FinanceBookingState {
  /// Seat held, journey not taken: draft / reserved / confirmed.
  live('قائم'),

  /// The passenger travelled: boarded / completed.
  travelled('تمت'),

  /// The seat was released. Nothing further will be collected on it, and
  /// anything already collected is a refund liability.
  cancelled('ملغي');

  final String label;
  const FinanceBookingState(this.label);

  static FinanceBookingState fromDb(String? value) => switch (value) {
    'cancelled' => FinanceBookingState.cancelled,
    'boarded' || 'completed' => FinanceBookingState.travelled,
    _ => FinanceBookingState.live,
  };
}

/// The context behind one money movement — everything an owner needs to
/// understand a row without opening four other modules.
///
/// Optional throughout: an office's older rows predate half these columns, and
/// a detail sheet that renders "—" for a fact the database never recorded is
/// honest, while one that refuses to open is not.
class FinanceEntryContext {
  /// Human-facing booking reference, e.g. `BK-000123`.
  final String? reference;

  final String? phone;

  /// The two ends of the journey, kept apart so the UI can compose them with
  /// [routeDirectionLabel] instead of trusting a pre-joined string to survive
  /// bidi layout.
  final String? origin;
  final String? destination;

  /// When the service happens (trip date) or begins (subscription start) — not
  /// the date the money moved, which is [FinanceLedgerEntry.date].
  final DateTime? serviceDate;

  final String? packageName;

  /// A payment receipt was uploaded. Finance does not open it — Bookings does —
  /// but knowing one exists is the difference between "chase the passenger" and
  /// "review the receipt".
  final bool hasReceipt;

  /// Why the payment was refused, when it was.
  final String? rejectionReason;

  const FinanceEntryContext({
    this.reference,
    this.phone,
    this.origin,
    this.destination,
    this.serviceDate,
    this.packageName,
    this.hasReceipt = false,
    this.rejectionReason,
  });

  static const empty = FinanceEntryContext();
}

class PaymentRecord {
  final String id;
  final String clientName;
  final String tripCode;
  final double amount;
  final FinancePaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime date;

  /// Where the seat stands. A fare on a cancelled seat is not "قيد التحصيل" —
  /// nobody is waiting for it — and counting it as such is how the module
  /// used to overstate what was still collectable.
  final FinanceBookingState bookingState;

  /// A receipt is uploaded and the desk has not decided yet. This is the one
  /// finance signal that maps to a real queue elsewhere in the console.
  final bool awaitingReview;

  final FinanceEntryContext context;

  const PaymentRecord({
    required this.id,
    required this.clientName,
    required this.tripCode,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.date,
    this.bookingState = FinanceBookingState.live,
    this.awaitingReview = false,
    this.context = FinanceEntryContext.empty,
  });

  PaymentRecord copyWith({
    String? id,
    String? clientName,
    String? tripCode,
    double? amount,
    FinancePaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? date,
    FinanceBookingState? bookingState,
    bool? awaitingReview,
    FinanceEntryContext? context,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      tripCode: tripCode ?? this.tripCode,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      date: date ?? this.date,
      bookingState: bookingState ?? this.bookingState,
      awaitingReview: awaitingReview ?? this.awaitingReview,
      context: context ?? this.context,
    );
  }
}

class RefundRequest {
  final String id;
  final String transactionId;
  final String clientName;
  final double amount;
  final DateTime date;
  final RefundStatus status;
  final String reason;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.status,
    required this.reason,
  });

  RefundRequest copyWith({
    String? id,
    String? transactionId,
    String? clientName,
    double? amount,
    DateTime? date,
    RefundStatus? status,
    String? reason,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
    );
  }
}

class SubscriptionRecord {
  final String id;
  final String clientName;
  final String packageName;

  /// The **sold** price of the package. Not necessarily what was collected —
  /// see [paidAmount].
  final double amount;

  /// What the office has actually received against [amount].
  ///
  /// The two diverge on part-paid packages, and the module used to file the
  /// whole [amount] as collected the moment the subscription went active. That
  /// counted money that had not arrived.
  final double paidAmount;

  /// Still owed on this package. Reported as outstanding, never as revenue.
  final double remainingAmount;

  /// The package's receipt has been uploaded and nobody has decided on it yet.
  final bool awaitingReview;

  /// Purchase date — the date the money moved, and therefore the date the
  /// ledger files it under. [startDate] is when the *rides* begin, which can be
  /// a different day entirely.
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final int remainingRides;
  final int tripsCount;
  final int tripsUsed;

  const SubscriptionRecord({
    required this.id,
    required this.clientName,
    required this.packageName,
    required this.amount,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.remainingRides,
    this.tripsCount = 0,
    this.tripsUsed = 0,
    double? paidAmount,
    this.remainingAmount = 0,
    this.awaitingReview = false,
  }) : paidAmount = paidAmount ?? amount;

  SubscriptionRecord copyWith({
    String? id,
    String? clientName,
    String? packageName,
    double? amount,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    int? remainingRides,
    int? tripsCount,
    int? tripsUsed,
    double? paidAmount,
    double? remainingAmount,
    bool? awaitingReview,
  }) {
    return SubscriptionRecord(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      packageName: packageName ?? this.packageName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      remainingRides: remainingRides ?? this.remainingRides,
      tripsCount: tripsCount ?? this.tripsCount,
      tripsUsed: tripsUsed ?? this.tripsUsed,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      awaitingReview: awaitingReview ?? this.awaitingReview,
    );
  }
}

/// One money movement, whatever produced it. Trip bookings and package
/// purchases are two different tables but one ledger — reading them together is
/// the only way a revenue figure here can mean "all the money", and netting the
/// refunded rows out of it is the only way "صافي الإيراد" is real.
class FinanceLedgerEntry {
  final String id;
  final FinanceEntryType type;

  /// Who the money came from.
  final String party;

  /// What it was for — a route code for bookings, a package name for
  /// subscriptions.
  final String reference;

  /// Always positive; [PaymentStatus.refunded] is what marks money that came in
  /// and then went back out.
  final double amount;
  final FinancePaymentMethod? method;
  final PaymentStatus status;
  final DateTime date;

  /// Where the underlying seat stands, for bookings. Subscriptions have no seat
  /// and report [FinanceBookingState.live] while they are sold.
  final FinanceBookingState bookingState;

  /// A receipt is waiting for a decision at the desk.
  final bool awaitingReview;

  /// Money still owed on this row — the unpaid tail of a part-paid package.
  /// Zero for anything settled in one movement, which is almost everything.
  final double outstanding;

  final FinanceEntryContext context;

  const FinanceLedgerEntry({
    required this.id,
    required this.type,
    required this.party,
    required this.reference,
    required this.amount,
    required this.status,
    required this.date,
    this.method,
    this.bookingState = FinanceBookingState.live,
    this.awaitingReview = false,
    this.outstanding = 0,
    this.context = FinanceEntryContext.empty,
  });

  /// Money the office received *and kept* — the only figure that may be added
  /// into net revenue. Everything else is a promise, a dead row, or a reversal.
  bool get isRealised => status == PaymentStatus.success;

  /// Collected, then the seat was cancelled: the office is holding money it no
  /// longer has a service to deliver against. Not a refund yet — a refund that
  /// has not been decided, which is exactly why it belongs on an attention list
  /// and not silently inside net revenue.
  bool get isUnreleasedLiability =>
      status == PaymentStatus.success &&
      bookingState == FinanceBookingState.cancelled;

  /// A fare that is still genuinely expected: unpaid, on a seat that still
  /// exists. A pending amount on a cancelled seat is not collectable and is
  /// filed as [PaymentStatus.cancelled] by the datasource instead.
  bool get isCollectable =>
      status == PaymentStatus.pending &&
      bookingState != FinanceBookingState.cancelled;
}

/// Flattens the money-in sources into one chronological ledger.
///
/// Refunds are **not** appended as separate rows: an approved refund is already
/// mirrored on its booking as [PaymentStatus.refunded], and adding the
/// `refund_requests` row on top of it would subtract the same pound twice.
/// Those requests are read separately, as an outstanding-liability signal.
class FinanceLedger {
  const FinanceLedger._();

  /// How many booking transactions the ledger pulls. Everything on the finance
  /// screen is derived from this list, so the cap is the module's real horizon:
  /// when a load comes back full, the screen says so instead of quietly
  /// under-reporting the older end of the window.
  ///
  /// The number itself lives with the console's other row ceilings so they can
  /// be read against each other; this alias is what the module's own code and
  /// its tests have always called it.
  static const rowCap = DashboardQueryCaps.financeLedger;

  static List<FinanceLedgerEntry> build({
    required List<PaymentRecord> payments,
    required List<SubscriptionRecord> subscriptions,
  }) {
    final entries = <FinanceLedgerEntry>[
      for (final payment in payments)
        FinanceLedgerEntry(
          id: payment.id,
          type: FinanceEntryType.booking,
          party: payment.clientName,
          reference: payment.tripCode.isEmpty ? 'غير محدد' : payment.tripCode,
          amount: payment.amount,
          method: payment.paymentMethod,
          status: payment.status,
          date: payment.date,
          bookingState: payment.bookingState,
          awaitingReview: payment.awaitingReview,
          context: payment.context,
        ),
      for (final subscription in subscriptions)
        FinanceLedgerEntry(
          id: subscription.id,
          type: FinanceEntryType.subscription,
          party: subscription.clientName,
          reference: subscription.packageName,
          
          // The money that moved, not the price on the invoice. A part-paid
          // package files what arrived and reports the rest as outstanding.
          amount: subscriptionCollectedAmount(subscription),
          status: subscriptionMoneyStatus(subscription.status),
          date: subscription.createdAt,
          awaitingReview: subscription.awaitingReview,
          outstanding: subscription.status == SubscriptionStatus.cancelled
              ? 0
              : subscription.remainingAmount,
          context: FinanceEntryContext(
            packageName: subscription.packageName,
            serviceDate: subscription.startDate,
          ),
        ),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// What a subscription actually contributed to the ledger.
  ///
  /// [SubscriptionRecord.amount] is the **price**; a package can go active on a
  /// deposit, and filing the full price the moment it does is revenue the office
  /// has not received. A cancelled package contributed nothing at all.
  static double subscriptionCollectedAmount(SubscriptionRecord subscription) {
    return switch (subscription.status) {
      SubscriptionStatus.cancelled => subscription.amount,
      SubscriptionStatus.pendingPayment => subscription.amount,
      SubscriptionStatus.active ||
      SubscriptionStatus.expired => subscription.paidAmount,
    };
  }

  /// A cancelled package was never collected; one still awaiting payment is
  /// outstanding. Everything else (active or expired) was paid for.
  static PaymentStatus subscriptionMoneyStatus(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.active ||
      SubscriptionStatus.expired => PaymentStatus.success,
      SubscriptionStatus.pendingPayment => PaymentStatus.pending,
      SubscriptionStatus.cancelled => PaymentStatus.cancelled,
    };
  }
}

class RevenueMetrics {
  final double todayRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int activeSubscriptions;
  final double totalBookingsRevenue;
  final double totalSubscriptionsRevenue;

  const RevenueMetrics({
    required this.todayRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.activeSubscriptions,
    required this.totalBookingsRevenue,
    this.totalSubscriptionsRevenue = 0,
  });

  double get grandTotalRevenue =>
      totalBookingsRevenue + totalSubscriptionsRevenue;

  RevenueMetrics copyWith({
    double? todayRevenue,
    double? weeklyRevenue,
    double? monthlyRevenue,
    int? activeSubscriptions,
    double? totalBookingsRevenue,
    double? totalSubscriptionsRevenue,
  }) {
    return RevenueMetrics(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
      totalBookingsRevenue: totalBookingsRevenue ?? this.totalBookingsRevenue,
      totalSubscriptionsRevenue:
          totalSubscriptionsRevenue ?? this.totalSubscriptionsRevenue,
    );
  }
}
