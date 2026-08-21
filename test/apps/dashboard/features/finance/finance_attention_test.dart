import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_attention.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';

final _now = DateTime(2026, 8, 20, 12);

void main() {
  group('what needs a decision', () {
    test('an empty book is clear, not silent', () {
      final attention = FinanceAttention.from(
        ledger: const [],
        refundRequests: const [],
      );

      expect(attention.isClear, isTrue);
      expect(attention.totalItems, 0);
      expect(attention.totalAtRisk, 0);
    });

    test('undecided receipts are counted and priced', () {
      final attention = FinanceAttention.from(
        ledger: [
          _booking('a', 300, PaymentStatus.pending, awaitingReview: true),
          _booking('b', 210, PaymentStatus.pending, awaitingReview: true),
        ],
        refundRequests: const [],
      );

      final item = attention.items.single;
      expect(item.kind, FinanceAttentionKind.receiptsAwaitingReview);
      expect(item.count, 2);
      expect(item.amount, 510);
      expect(item.severity, FinanceAttentionSeverity.urgent);
    });

    test('a receipt is never counted twice as an unchased fare', () {
      // Both queues read the same predicate — unpaid, live seat — so without
      // the subtraction the same 300 would appear in two rows and the panel's
      // total would claim 600 was at stake.
      final attention = FinanceAttention.from(
        ledger: [
          _booking('a', 300, PaymentStatus.pending, awaitingReview: true),
          _booking('b', 120, PaymentStatus.pending),
        ],
        refundRequests: const [],
      );

      final review = attention.items.firstWhere(
        (i) => i.kind == FinanceAttentionKind.receiptsAwaitingReview,
      );
      final chase = attention.items.firstWhere(
        (i) => i.kind == FinanceAttentionKind.unpaidLiveBookings,
      );

      expect(review.amount, 300);
      expect(chase.amount, 120);
      expect(attention.totalAtRisk, 420);
    });

    test('money held against a cancelled seat is its own urgent queue', () {
      final attention = FinanceAttention.from(
        ledger: [
          _booking(
            'a',
            450,
            PaymentStatus.success,
            seat: FinanceBookingState.cancelled,
          ),
        ],
        refundRequests: const [],
      );

      final item = attention.items.single;
      expect(item.kind, FinanceAttentionKind.collectedOnCancelledSeat);
      expect(item.amount, 450);
      expect(item.kind.route, DashboardRoutes.bookings);
    });

    test('an unpaid fare on a cancelled seat is not a chase', () {
      // Nobody is waiting for it — the datasource already files it as
      // cancelled money, and the attention list must not resurrect it.
      final attention = FinanceAttention.from(
        ledger: [
          _booking(
            'a',
            450,
            PaymentStatus.cancelled,
            seat: FinanceBookingState.cancelled,
          ),
        ],
        refundRequests: const [],
      );

      expect(attention.isClear, isTrue);
    });

    test('only undecided refund requests count', () {
      final attention = FinanceAttention.from(
        ledger: const [],
        refundRequests: [
          _refund('r1', 68, RefundStatus.pending),
          _refund('r2', 200, RefundStatus.approved),
          _refund('r3', 90, RefundStatus.rejected),
        ],
      );

      final item = attention.items.single;
      expect(item.kind, FinanceAttentionKind.refundRequestsPending);
      expect(item.count, 1);
      expect(item.amount, 68);
      expect(item.kind.route, DashboardRoutes.wallet);
    });

    test('the unpaid tail of a part-paid package is a queue', () {
      final attention = FinanceAttention.from(
        ledger: [
          FinanceLedgerEntry(
            id: 's1',
            type: FinanceEntryType.subscription,
            party: 'منى سعيد',
            reference: 'الباقة الشهرية',
            amount: 400,
            status: PaymentStatus.success,
            date: _now,
            outstanding: 320,
          ),
        ],
        refundRequests: const [],
      );

      final item = attention.items.single;
      expect(item.kind, FinanceAttentionKind.subscriptionsPartPaid);
      expect(item.amount, 320, reason: 'the tail, not the whole price');
      expect(item.kind.route, DashboardRoutes.subscriptions);
    });

    test('a broken control identity outranks every other queue', () {
      final attention = FinanceAttention.from(
        ledger: [
          _booking('a', 300, PaymentStatus.pending, awaitingReview: true),
        ],
        refundRequests: const [],
        statements: const FinanceMoneyStatements(
          revenue: 100,
          cash: 100,
          liabilityStart: 0,
          liabilityEnd: 0,
          promotionalCost: 0,
          cashIn: 100,
          cashOut: 0,
          refundsTotal: 0,
          refundsToWallet: 0,
        ).copyBroken(),
      );

      expect(attention.items.first.kind, FinanceAttentionKind.identityBroken);
      expect(attention.items.first.kind.route, isNull);
    });

    test('a balanced identity adds no row', () {
      final attention = FinanceAttention.from(
        ledger: const [],
        refundRequests: const [],
        statements: const FinanceMoneyStatements.empty(),
      );

      expect(attention.isClear, isTrue);
    });

    test('urgent queues rank above warnings, then by money', () {
      final attention = FinanceAttention.from(
        ledger: [
          _booking('chase', 5000, PaymentStatus.pending),
          _booking('review', 100, PaymentStatus.pending, awaitingReview: true),
          _booking(
            'stranded',
            900,
            PaymentStatus.success,
            seat: FinanceBookingState.cancelled,
          ),
        ],
        refundRequests: const [],
      );

      expect(attention.items.map((i) => i.kind), [
        // Urgent first, ordered by exposure — the 5,000 chase is a warning and
        // still sorts last, because "how loudly does this ask" outranks "how
        // big is it".
        FinanceAttentionKind.collectedOnCancelledSeat,
        FinanceAttentionKind.receiptsAwaitingReview,
        FinanceAttentionKind.unpaidLiveBookings,
      ]);
    });

    test('the identity gap is excluded from the money at risk', () {
      // It is a measurement error, not an amount anyone owes; adding it to a
      // figure labelled "money" would be the same category mistake the
      // three-statement model exists to prevent.
      final attention = FinanceAttention.from(
        ledger: [_booking('a', 300, PaymentStatus.pending)],
        refundRequests: const [],
        statements: const FinanceMoneyStatements(
          revenue: 100,
          cash: 100,
          liabilityStart: 0,
          liabilityEnd: 0,
          promotionalCost: 0,
          cashIn: 100,
          cashOut: 0,
          refundsTotal: 0,
          refundsToWallet: 0,
        ).copyBroken(),
      );

      expect(attention.totalAtRisk, 300);
    });
  });

  test('every queue with a route points at a module that can clear it', () {
    for (final kind in FinanceAttentionKind.values) {
      expect(kind.title, isNotEmpty);
      expect(kind.action, isNotEmpty);
      expect(kind.unit, isNotEmpty);
      if (kind == FinanceAttentionKind.identityBroken) {
        expect(kind.route, isNull);
      } else {
        expect(kind.route, isNotNull);
        expect(kind.route, startsWith('/'));
      }
    }
  });
}

FinanceLedgerEntry _booking(
  String id,
  double amount,
  PaymentStatus status, {
  bool awaitingReview = false,
  FinanceBookingState seat = FinanceBookingState.live,
}) => FinanceLedgerEntry(
  id: id,
  type: FinanceEntryType.booking,
  party: 'عميل $id',
  reference: 'مسار',
  amount: amount,
  status: status,
  date: _now,
  bookingState: seat,
  awaitingReview: awaitingReview,
);

RefundRequest _refund(String id, double amount, RefundStatus status) =>
    RefundRequest(
      id: id,
      transactionId: 'BK-$id',
      clientName: 'عميل',
      amount: amount,
      date: _now,
      status: status,
      reason: '',
    );

/// A statements value whose control identity does not balance.
extension on FinanceMoneyStatements {
  FinanceMoneyStatements copyBroken() => FinanceMoneyStatements(
    revenue: revenue,
    cash: cash,
    liabilityStart: liabilityStart,
    liabilityEnd: liabilityEnd,
    promotionalCost: promotionalCost,
    cashIn: cashIn + 25,
    cashOut: cashOut,
    refundsTotal: refundsTotal,
    refundsToWallet: refundsToWallet,
  );
}
