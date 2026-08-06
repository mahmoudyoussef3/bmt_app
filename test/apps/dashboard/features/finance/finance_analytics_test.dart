import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';

/// A fixed clock: every window boundary in these tests is measured from it.
final _now = DateTime(2026, 7, 31, 12);

void main() {
  group('FinanceAnalytics arithmetic', () {
    test('net revenue excludes pending, cancelled and reversed money', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 60, PaymentStatus.pending, daysAgo: 1),
        _booking('c', 40, PaymentStatus.cancelled, daysAgo: 1),
        _booking('d', 30, PaymentStatus.refunded, daysAgo: 2),
      ]);

      expect(analytics.netRevenue, 100);
      expect(analytics.pending, 60);
      expect(analytics.cancelled, 40);
      expect(analytics.refunded, 30);
    });

    test('gross received counts reversed money once, net counts it zero', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 30, PaymentStatus.refunded, daysAgo: 1),
      ]);

      // 130 came in, 30 went back, 100 stayed — the statement must balance.
      expect(analytics.grossReceived, 130);
      expect(analytics.refunded, 30);
      expect(
        analytics.netRevenue,
        analytics.grossReceived - analytics.refunded,
      );
    });

    test('bookings and subscriptions revenue sum to net revenue', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _subscription('s', 250, SubscriptionStatus.active, daysAgo: 3),
      ]);

      expect(analytics.bookingsRevenue, 100);
      expect(analytics.subscriptionsRevenue, 250);
      expect(
        analytics.bookingsRevenue + analytics.subscriptionsRevenue,
        analytics.netRevenue,
      );
    });

    test('collection rate is collected over everything billed', () {
      final analytics = _analyticsFor([
        _booking('a', 75, PaymentStatus.success, daysAgo: 0),
        _booking('b', 25, PaymentStatus.pending, daysAgo: 0),
      ]);

      expect(analytics.billed, 100);
      expect(analytics.collectionRate, 0.75);
    });

    test('average ticket divides by collected transactions only', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 200, PaymentStatus.success, daysAgo: 1),
        _booking('c', 999, PaymentStatus.pending, daysAgo: 1),
      ]);

      expect(analytics.paidCount, 2);
      expect(analytics.averageTicket, 150);
    });

    test(
      'rates stay at zero instead of dividing by zero on an empty period',
      () {
        final analytics = _analyticsFor(const []);

        expect(analytics.netRevenue, 0);
        expect(analytics.collectionRate, 0);
        expect(analytics.refundRate, 0);
        expect(analytics.averageTicket, 0);
        expect(analytics.routeConcentration, 0);
        expect(analytics.daily, isEmpty);
        expect(analytics.bestDay, isNull);
      },
    );
  });

  group('FinanceAnalytics windowing', () {
    test('the period bounds which entries count', () {
      final ledger = [
        _booking('today', 100, PaymentStatus.success, daysAgo: 0),
        _booking('lastWeek', 50, PaymentStatus.success, daysAgo: 5),
        _booking('lastMonth', 20, PaymentStatus.success, daysAgo: 40),
      ];

      expect(
        _analyticsFor(ledger, period: FinancePeriod.today).netRevenue,
        100,
      );
      expect(_analyticsFor(ledger, period: FinancePeriod.week).netRevenue, 150);
      expect(
        _analyticsFor(ledger, period: FinancePeriod.month).netRevenue,
        150,
      );
      expect(_analyticsFor(ledger, period: FinancePeriod.all).netRevenue, 170);
    });

    test('the previous window is equally long and does not overlap', () {
      final ledger = [
        _booking('current', 100, PaymentStatus.success, daysAgo: 1),
        _booking('previous', 80, PaymentStatus.success, daysAgo: 8),
      ];

      final analytics = _analyticsFor(ledger, period: FinancePeriod.week);

      expect(analytics.netRevenue, 100);
      expect(analytics.previous!.netRevenue, 80);
      expect(analytics.netRevenueChange, closeTo(0.25, 0.0001));
    });

    test('all-time has no previous window to compare against', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
      ], period: FinancePeriod.all);

      expect(analytics.hasComparison, isFalse);
      expect(analytics.netRevenueChange, isNull);
    });

    test(
      'change is null rather than infinite when the base period was zero',
      () {
        final analytics = _analyticsFor([
          _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        ], period: FinancePeriod.week);

        expect(analytics.previous!.netRevenue, 0);
        expect(analytics.netRevenueChange, isNull);
      },
    );

    test('a bounded window fills quiet days with zeros', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 100, PaymentStatus.success, daysAgo: 6),
      ], period: FinancePeriod.week);

      expect(analytics.daily, hasLength(7));
      expect(analytics.activeDays, 2);
      expect(analytics.daily.where((d) => d.net == 0), hasLength(5));
    });

    test('all-time keeps only the days that exist', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 100, PaymentStatus.success, daysAgo: 200),
      ], period: FinancePeriod.all);

      expect(analytics.daily, hasLength(2));
    });
  });

  group('FinanceAnalytics breakdowns', () {
    test('rankings describe kept money only', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0, route: 'مسار أ'),
        _booking('b', 900, PaymentStatus.pending, daysAgo: 0, route: 'مسار ب'),
        _booking('c', 500, PaymentStatus.refunded, daysAgo: 0, route: 'مسار ج'),
      ]);

      expect(analytics.byRoute, hasLength(1));
      expect(analytics.byRoute.first.label, 'مسار أ');
      expect(analytics.routeConcentration, 1.0);
    });

    test('breakdowns are sorted by amount, descending', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0, route: 'صغير'),
        _booking('b', 400, PaymentStatus.success, daysAgo: 0, route: 'كبير'),
        _booking('c', 250, PaymentStatus.success, daysAgo: 0, route: 'متوسط'),
      ]);

      expect(analytics.byRoute.map((r) => r.label), ['كبير', 'متوسط', 'صغير']);
    });

    test('weekday breakdown always covers the full Saturday-first week', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
      ]);

      expect(analytics.byWeekday, hasLength(7));
      expect(analytics.byWeekday.first.label, 'السبت');
      expect(analytics.byWeekday.last.label, 'الجمعة');
    });

    test('cumulative series only ever climbs', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 50, PaymentStatus.success, daysAgo: 3),
        _booking('c', 25, PaymentStatus.success, daysAgo: 5),
      ], period: FinancePeriod.week);

      final cumulative = analytics.cumulativeDaily;
      for (var i = 1; i < cumulative.length; i++) {
        expect(cumulative[i].net, greaterThanOrEqualTo(cumulative[i - 1].net));
      }
      expect(cumulative.last.net, 175);
    });
  });

  group('FinanceStatement', () {
    test('the statement carries the same figures as the analytics', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 30, PaymentStatus.refunded, daysAgo: 1),
        _subscription('s', 250, SubscriptionStatus.active, daysAgo: 2),
      ]);

      final statement = analytics.toStatement(generatedAt: _now);
      double lineFor(String label) =>
          statement.summary.firstWhere((line) => line.label == label).amount;

      expect(lineFor('إيرادات الحجوزات'), 100);
      expect(lineFor('إيرادات الاشتراكات'), 250);
      expect(lineFor('المرتجعات المنفذة'), 30);
      expect(lineFor('إجمالي المتحصلات'), 380);
      expect(lineFor('صافي الإيراد'), 350);
      expect(statement.entries, hasLength(3));
    });

    test('pending and cancelled are memo lines, outside the total', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
        _booking('b', 70, PaymentStatus.pending, daysAgo: 0),
      ]);

      final statement = analytics.toStatement(generatedAt: _now);
      final memos = statement.summary.where((line) => line.isMemo).toList();

      expect(
        memos.map((line) => line.label),
        contains('قيد التحصيل (خارج الصافي)'),
      );
      expect(statement.summary.firstWhere((line) => line.isTotal).amount, 100);
    });
  });

  group('FinanceLedger', () {
    test('subscription status maps onto money status', () {
      expect(
        FinanceLedger.subscriptionMoneyStatus(SubscriptionStatus.active),
        PaymentStatus.success,
      );
      expect(
        FinanceLedger.subscriptionMoneyStatus(SubscriptionStatus.expired),
        PaymentStatus.success,
      );
      expect(
        FinanceLedger.subscriptionMoneyStatus(
          SubscriptionStatus.pendingPayment,
        ),
        PaymentStatus.pending,
      );
      expect(
        FinanceLedger.subscriptionMoneyStatus(SubscriptionStatus.cancelled),
        PaymentStatus.cancelled,
      );
    });

    test('build() merges both sources newest first', () {
      final ledger = FinanceLedger.build(
        payments: [
          PaymentRecord(
            id: 'old',
            clientName: 'أ',
            tripCode: 'مسار',
            amount: 10,
            paymentMethod: FinancePaymentMethod.cash,
            status: PaymentStatus.success,
            date: _now.subtract(const Duration(days: 5)),
          ),
        ],
        subscriptions: [
          SubscriptionRecord(
            id: 'new',
            clientName: 'ب',
            packageName: 'باقة',
            amount: 20,
            createdAt: _now,
            startDate: _now,
            endDate: _now.add(const Duration(days: 30)),
            status: SubscriptionStatus.active,
            remainingRides: 4,
          ),
        ],
      );

      expect(ledger.map((e) => e.id), ['new', 'old']);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // The three-statement model (§7).
  //
  // Every case below is a worked example from the design's control-identity
  // table. They exist because the previous single-number model got the third
  // one wrong: it reported zero revenue for an office that had earned 300.
  // ═══════════════════════════════════════════════════════════════════════════
  group('FinanceMoneyStatements — the §7.2 control identity', () {
    test('1. book 300 cash: revenue 300, cash 300, liability unchanged', () {
      final statements = _statementsFor(
        ledger: [_booking('a', 300, PaymentStatus.success, daysAgo: 0)],
      );

      expect(statements.revenue, 300);
      expect(statements.cash, 300);
      expect(statements.deltaLiability, 0);
      expect(statements.identityHolds, isTrue);
    });

    test('2. …refunded 300 to wallet: revenue 0, cash still 300, ΔL +300', () {
      final statements = _statementsFor(
        ledger: [_booking('a', 300, PaymentStatus.success, daysAgo: 2)],
        refunds: [_refund(300, toWallet: true, daysAgo: 1)],
        movements: [_movement(WalletMovementKind.refund, 300, daysAgo: 1)],
      );

      // The office still holds the cash; it now owes 300 back as service.
      expect(statements.revenue, 0);
      expect(statements.cash, 300);
      expect(statements.deltaLiability, 300);
      expect(statements.identityHolds, isTrue);
    });

    test('3. …customer rebooks with the wallet: revenue is 300, not 0', () {
      // THE case revision 1 got wrong. Two fares were sold (300 + 300), one
      // refund was granted (300), and the second fare was tendered from the
      // wallet — so no second pound of cash arrived.
      final statements = _statementsFor(
        ledger: [
          _booking('a', 300, PaymentStatus.success, daysAgo: 3),
          _booking('b', 300, PaymentStatus.success, daysAgo: 1),
        ],
        refunds: [_refund(300, toWallet: true, daysAgo: 2)],
        movements: [
          _movement(WalletMovementKind.refund, 300, daysAgo: 2),
          _movement(WalletMovementKind.walletSpend, -300, daysAgo: 1),
        ],
        // V2 shape: the wallet-paid fare is in the fare total but not in the
        // external tender, because a wallet leg is never written to
        // `booking_payments`.
        externalTender: 300,
      );

      expect(statements.revenue, 300);
      expect(statements.cash, 300);
      expect(statements.deltaLiability, 0);
      expect(statements.identityHolds, isTrue);
    });

    test('4. …refunded 300 to InstaPay instead: cash out, no liability', () {
      final statements = _statementsFor(
        ledger: [_booking('a', 300, PaymentStatus.success, daysAgo: 2)],
        refunds: [_refund(300, toWallet: false, daysAgo: 1)],
      );

      expect(statements.revenue, 0);
      expect(statements.cash, 0);
      expect(statements.cashOut, 300);
      expect(statements.deltaLiability, 0);
      expect(statements.identityHolds, isTrue);
    });

    test('5. cashback 100, unspent: promotional cost 100, liability +100', () {
      final statements = _statementsFor(
        ledger: const [],
        movements: [_movement(WalletMovementKind.cashback, 100, daysAgo: 1)],
      );

      expect(statements.revenue, 0);
      expect(statements.cash, 0);
      expect(statements.promotionalCost, 100);
      expect(statements.deltaLiability, 100);
      expect(statements.identityHolds, isTrue);
    });

    test('6. cashback 100 spent on a 100 ride: revenue 100, no cash', () {
      final statements = _statementsFor(
        ledger: [_booking('a', 100, PaymentStatus.success, daysAgo: 1)],
        movements: [
          _movement(WalletMovementKind.cashback, 100, daysAgo: 2),
          _movement(WalletMovementKind.walletSpend, -100, daysAgo: 1),
        ],
        externalTender: 0,
      );

      expect(statements.revenue, 100);
      expect(statements.cash, 0);
      expect(statements.promotionalCost, 100);
      expect(statements.deltaLiability, 0);
      expect(statements.identityHolds, isTrue);
    });

    test('promotional cost is net of clawbacks', () {
      // A wrongly granted cashback that is debited back is not an incentive the
      // office paid for; counting the grant without the clawback would both
      // overstate the expense and break the identity.
      final statements = _statementsFor(
        ledger: const [],
        movements: [
          _movement(WalletMovementKind.cashback, 100, daysAgo: 2),
          _movement(WalletMovementKind.manualDebit, -100, daysAgo: 1),
        ],
      );

      expect(statements.promotionalCost, 0);
      expect(statements.deltaLiability, 0);
      expect(statements.identityHolds, isTrue);
    });

    test('liability at the window open is back-computed from the ledger', () {
      // Law L2: only the *current* balance is fetched. Every historical position
      // is recovered by unwinding the movements that came after the window.
      final statements = _statementsFor(
        ledger: const [],
        movements: [
          _movement(WalletMovementKind.cashback, 40, daysAgo: 3),
          // Outside the window: must be unwound out of the closing balance.
          _movement(WalletMovementKind.cashback, 25, daysAgo: -1),
        ],
        currentLiability: 65,
      );

      expect(statements.liabilityEnd, 40);
      expect(statements.liabilityStart, 0);
      expect(statements.deltaLiability, 40);
    });

    test('an office that has never issued credit reports zeros, not nulls', () {
      final analytics = _analyticsFor([
        _booking('a', 100, PaymentStatus.success, daysAgo: 0),
      ]);

      expect(analytics.statements.liabilityEnd, 0);
      expect(analytics.statements.promotionalCost, 0);
      expect(analytics.statements.revenue, 100);
      expect(analytics.statements.identityHolds, isTrue);
    });
  });
}

FinanceAnalytics _analyticsFor(
  List<FinanceLedgerEntry> ledger, {
  FinancePeriod period = FinancePeriod.month,
}) {
  return FinanceAnalytics.from(ledger: ledger, period: period, now: _now);
}

FinanceLedgerEntry _booking(
  String id,
  double amount,
  PaymentStatus status, {
  required int daysAgo,
  String route = 'مسار افتراضي',
}) {
  return FinanceLedgerEntry(
    id: id,
    type: FinanceEntryType.booking,
    party: 'عميل $id',
    reference: route,
    amount: amount,
    method: FinancePaymentMethod.instapay,
    status: status,
    date: _now.subtract(Duration(days: daysAgo)),
  );
}

FinanceLedgerEntry _subscription(
  String id,
  double amount,
  SubscriptionStatus status, {
  required int daysAgo,
}) {
  return FinanceLedgerEntry(
    id: id,
    type: FinanceEntryType.subscription,
    party: 'مشترك $id',
    reference: 'باقة شهرية',
    amount: amount,
    status: FinanceLedger.subscriptionMoneyStatus(status),
    date: _now.subtract(Duration(days: daysAgo)),
  );
}

/// Builds the three statements over the default month window.
///
/// `soldFare` is taken from the ledger (which is built from booking fares);
/// `externalTender` defaults to the same figure because V1 has no wallet
/// tender, and is overridable so the V2 split-tender cases can be expressed.
FinanceMoneyStatements _statementsFor({
  required List<FinanceLedgerEntry> ledger,
  List<SettledRefund> refunds = const [],
  List<WalletMovement> movements = const [],
  double? externalTender,
  double? currentLiability,
}) {
  final analytics = _analyticsFor(ledger);
  final fare = analytics.grossReceived;

  return FinanceMoneyStatements.from(
    soldFare: fare,
    externalTender: externalTender ?? fare,
    wallet: WalletFinancePosition(
      currentLiability:
          currentLiability ??
          movements.fold<double>(0, (sum, m) => sum + m.amount),
      movements: movements,
      refunds: refunds,
    ),
    range: analytics.range,
  );
}

SettledRefund _refund(
  double amount, {
  required bool toWallet,
  required int daysAgo,
}) => SettledRefund(
  settledAt: _now.subtract(Duration(days: daysAgo)),
  amount: amount,
  toWallet: toWallet,
);

/// [daysAgo] may be negative to place a movement *after* the window closes,
/// which is how the back-computation of the opening balance is exercised.
WalletMovement _movement(
  WalletMovementKind kind,
  double amount, {
  required int daysAgo,
}) => WalletMovement(
  date: _now.subtract(Duration(days: daysAgo)),
  kind: kind,
  amount: amount,
);
