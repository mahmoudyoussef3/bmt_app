import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';

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
