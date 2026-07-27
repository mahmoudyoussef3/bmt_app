import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/booking_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';

void main() {
  group('PaymentStatus mirrors the database allowlist', () {
    // operation_bookings_payment_status_check, read from the live database
    // 2026-07-27. `cancelled` was missing from the Dart enum, so the model's
    // name-lookup fell back to `pending` and a cancelled payment rendered as
    // "awaiting payment" — telling operators money was still expected.
    const dbValues = {
      'pending',
      'submitted',
      'underReview',
      'approved',
      'rejected',
      'refunded',
      'failed',
      'cancelled',
    };

    test('every database value has an enum constant of the same name', () {
      final names = PaymentStatus.values.map((s) => s.name).toSet();
      expect(names, dbValues);
    });

    test('cancelled exists and is not conflated with pending', () {
      expect(PaymentStatus.cancelled.label, isNot(PaymentStatus.pending.label));
      expect(PaymentStatus.cancelled.isClosed, isTrue);
      expect(PaymentStatus.pending.isClosed, isFalse);
    });
  });

  group('BookingStatus transitions', () {
    test('follows the journey forward', () {
      expect(
        BookingStatus.draft.canTransitionTo(BookingStatus.reserved),
        isTrue,
      );
      expect(
        BookingStatus.reserved.canTransitionTo(BookingStatus.confirmed),
        isTrue,
      );
      expect(
        BookingStatus.confirmed.canTransitionTo(BookingStatus.boarded),
        isTrue,
      );
      expect(
        BookingStatus.boarded.canTransitionTo(BookingStatus.completed),
        isTrue,
      );
    });

    test('never runs backwards', () {
      expect(
        BookingStatus.confirmed.canTransitionTo(BookingStatus.reserved),
        isFalse,
      );
      expect(
        BookingStatus.boarded.canTransitionTo(BookingStatus.confirmed),
        isFalse,
      );
      expect(
        BookingStatus.completed.canTransitionTo(BookingStatus.boarded),
        isFalse,
      );
    });

    test('cancellation is available until the passenger has travelled', () {
      expect(
        BookingStatus.draft.canTransitionTo(BookingStatus.cancelled),
        isTrue,
      );
      expect(
        BookingStatus.reserved.canTransitionTo(BookingStatus.cancelled),
        isTrue,
      );
      expect(
        BookingStatus.confirmed.canTransitionTo(BookingStatus.cancelled),
        isTrue,
      );
      // Once boarded there is no seat to release; a no-show is cancelled before
      // departure, not after.
      expect(
        BookingStatus.boarded.canTransitionTo(BookingStatus.cancelled),
        isFalse,
      );
    });

    test('terminal states are terminal', () {
      for (final terminal in [
        BookingStatus.completed,
        BookingStatus.cancelled,
      ]) {
        expect(terminal.isClosed, isTrue);
        for (final next in BookingStatus.values) {
          expect(
            terminal.canTransitionTo(next),
            isFalse,
            reason: '${terminal.name} must not move to ${next.name}',
          );
        }
      }
    });

    test('seat occupancy and travel are classified correctly', () {
      expect(BookingStatus.reserved.holdsSeat, isTrue);
      expect(BookingStatus.confirmed.holdsSeat, isTrue);
      expect(BookingStatus.boarded.holdsSeat, isTrue);
      expect(BookingStatus.cancelled.holdsSeat, isFalse);
      expect(BookingStatus.draft.holdsSeat, isFalse);

      expect(BookingStatus.boarded.hasTravelled, isTrue);
      expect(BookingStatus.completed.hasTravelled, isTrue);
      expect(BookingStatus.confirmed.hasTravelled, isFalse);
    });
  });

  group('PaymentStatus transitions', () {
    test('a submitted receipt can be approved, rejected or reviewed', () {
      const from = PaymentStatus.submitted;
      expect(from.canTransitionTo(PaymentStatus.approved), isTrue);
      expect(from.canTransitionTo(PaymentStatus.rejected), isTrue);
      expect(from.canTransitionTo(PaymentStatus.underReview), isTrue);
    });

    test('a rejected receipt can be replaced by a new one', () {
      // The whole point of telling a passenger why their receipt failed is that
      // they can upload a better one without rebooking.
      expect(
        PaymentStatus.rejected.canTransitionTo(PaymentStatus.submitted),
        isTrue,
      );
    });

    test('approved money is reversed, never un-approved', () {
      const from = PaymentStatus.approved;
      expect(from.canTransitionTo(PaymentStatus.refunded), isTrue);
      expect(from.canTransitionTo(PaymentStatus.pending), isFalse);
      expect(from.canTransitionTo(PaymentStatus.rejected), isFalse);
      expect(from.canTransitionTo(PaymentStatus.submitted), isFalse);
    });

    test('refunded and cancelled are terminal', () {
      for (final terminal in [
        PaymentStatus.refunded,
        PaymentStatus.cancelled,
      ]) {
        expect(terminal.isClosed, isTrue);
        for (final next in PaymentStatus.values) {
          expect(terminal.canTransitionTo(next), isFalse);
        }
      }
    });

    test('classifies settled / needs-review / unsettled', () {
      expect(PaymentStatus.approved.isSettled, isTrue);
      expect(PaymentStatus.submitted.needsReview, isTrue);
      expect(PaymentStatus.underReview.needsReview, isTrue);
      expect(PaymentStatus.approved.needsReview, isFalse);
      expect(PaymentStatus.pending.isUnsettled, isTrue);
      expect(PaymentStatus.rejected.isUnsettled, isTrue);
      expect(PaymentStatus.failed.isUnsettled, isTrue);
      expect(PaymentStatus.approved.isUnsettled, isFalse);
    });
  });

  group('Contradiction detection', () {
    test('paid-but-cancelled is critical', () {
      final issues = detectBookingIssues(
        status: BookingStatus.cancelled,
        paymentStatus: PaymentStatus.approved,
      );
      expect(issues.single.code, 'paid_but_cancelled');
      expect(issues.single.severity, BookingIssueSeverity.critical);
    });

    test('confirmed-without-payment is critical', () {
      for (final unpaid in [
        PaymentStatus.pending,
        PaymentStatus.submitted,
        PaymentStatus.rejected,
        PaymentStatus.failed,
      ]) {
        final issues = detectBookingIssues(
          status: BookingStatus.confirmed,
          paymentStatus: unpaid,
        );
        expect(
          issues.map((i) => i.code),
          contains('confirmed_without_payment'),
          reason: 'confirmed + ${unpaid.name} must be flagged',
        );
      }
    });

    test('travelled-without-payment is critical', () {
      for (final status in [BookingStatus.boarded, BookingStatus.completed]) {
        final issues = detectBookingIssues(
          status: status,
          paymentStatus: PaymentStatus.pending,
        );
        expect(
          issues.map((i) => i.code),
          contains('travelled_without_payment'),
        );
      }
    });

    test('completed-but-refunded is a warning, not an alarm', () {
      final issues = detectBookingIssues(
        status: BookingStatus.completed,
        paymentStatus: PaymentStatus.refunded,
      );
      expect(issues.single.code, 'completed_but_refunded');
      expect(issues.single.severity, BookingIssueSeverity.warning);
    });

    test('the healthy combinations raise nothing', () {
      const healthy = [
        (BookingStatus.reserved, PaymentStatus.pending),
        (BookingStatus.reserved, PaymentStatus.submitted),
        (BookingStatus.reserved, PaymentStatus.underReview),
        (BookingStatus.confirmed, PaymentStatus.approved),
        (BookingStatus.boarded, PaymentStatus.approved),
        (BookingStatus.completed, PaymentStatus.approved),
        (BookingStatus.cancelled, PaymentStatus.refunded),
        (BookingStatus.cancelled, PaymentStatus.cancelled),
        (BookingStatus.draft, PaymentStatus.pending),
      ];
      for (final (status, payment) in healthy) {
        expect(
          detectBookingIssues(status: status, paymentStatus: payment),
          isEmpty,
          reason: '${status.name} + ${payment.name} should be clean',
        );
      }
    });

    test(
      'cancelled + refunded is the CORRECT resolution of paid-but-cancelled',
      () {
        // Refunding is how an operator fixes the critical case, so the fixed state
        // must itself be clean — otherwise the warning never clears.
        expect(
          detectBookingIssues(
            status: BookingStatus.cancelled,
            paymentStatus: PaymentStatus.approved,
          ),
          isNotEmpty,
        );
        expect(
          detectBookingIssues(
            status: BookingStatus.cancelled,
            paymentStatus: PaymentStatus.refunded,
          ),
          isEmpty,
        );
      },
    );
  });

  group('Next action resolution', () {
    BookingNextAction act(
      BookingStatus status,
      PaymentStatus payment, {
      bool hasReceipt = true,
    }) => resolveNextAction(
      status: status,
      paymentStatus: payment,
      hasReceipt: hasReceipt,
    );

    test('a contradiction outranks routine work', () {
      // Acting on a booking whose money and seat disagree makes it worse, so the
      // contradiction must win even though the payment also "needs review".
      final action = act(BookingStatus.confirmed, PaymentStatus.submitted);
      expect(action.kind, BookingActionKind.resolveContradiction);
      expect(action.reason, contains('المقعد محجوز دون تحصيل'));
    });

    test('a submitted receipt is the review queue', () {
      final action = act(BookingStatus.reserved, PaymentStatus.submitted);
      expect(action.kind, BookingActionKind.approvePayment);
      expect(action.isActionable, isTrue);
    });

    test('needs-review with no receipt asks for one instead', () {
      final action = act(
        BookingStatus.reserved,
        PaymentStatus.submitted,
        hasReceipt: false,
      );
      expect(action.kind, BookingActionKind.requestReview);
      expect(action.reason, contains('لا يوجد إيصال'));
    });

    test('a pending payment is waiting on the passenger, not the desk', () {
      final action = act(BookingStatus.reserved, PaymentStatus.pending);
      expect(action.kind, BookingActionKind.none);
      expect(action.label, 'بانتظار العميل');
    });

    test('a rejected receipt is waiting on the passenger', () {
      final action = act(BookingStatus.reserved, PaymentStatus.rejected);
      expect(action.kind, BookingActionKind.none);
      expect(action.label, 'بانتظار العميل');
    });

    test('a confirmed and paid booking needs nothing', () {
      final action = act(BookingStatus.confirmed, PaymentStatus.approved);
      expect(action.kind, BookingActionKind.none);
      expect(action.label, 'جاهز للسفر');
    });

    test('a closed booking offers no action', () {
      expect(
        act(BookingStatus.cancelled, PaymentStatus.refunded).kind,
        BookingActionKind.none,
      );
      expect(
        act(BookingStatus.completed, PaymentStatus.approved).kind,
        BookingActionKind.none,
      );
    });

    test('every combination resolves without throwing', () {
      // The resolver is a total function: an unexpected pair from the database
      // must produce a defensible "no action" rather than an exception on the
      // operator's screen.
      for (final status in BookingStatus.values) {
        for (final payment in PaymentStatus.values) {
          for (final receipt in [true, false]) {
            final action = act(status, payment, hasReceipt: receipt);
            expect(action.label, isNotEmpty);
            expect(action.reason, isNotEmpty);
          }
        }
      }
    });
  });
}
