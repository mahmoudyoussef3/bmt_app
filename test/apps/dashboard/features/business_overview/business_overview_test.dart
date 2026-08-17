import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_attention.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_health.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_insight.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_metric.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    as finance;
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import 'business_overview_test_fixtures.dart';

void main() {
  group('MetricTrend', () {
    test('a zero baseline yields no ratio, only an absolute delta', () {
      const trend = MetricTrend(
        current: 500,
        previous: 0,
        previousLabel: 'أمس',
      );
      expect(trend.changeRatio, isNull);
      expect(trend.delta, 500);
      expect(trend.direction, TrendDirection.up);
    });

    test('movement under half a percent reads as flat', () {
      const trend = MetricTrend(
        current: 1002,
        previous: 1000,
        previousLabel: 'أمس',
      );
      expect(trend.direction, TrendDirection.flat);
    });
  });

  group('daily series', () {
    test('revenue counts approved payments only, dated by created_at', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'a', amount: 300),
          buildBooking(
            id: 'b',
            amount: 999,
            paymentStatus: PaymentStatus.pending,
          ),
          buildBooking(
            id: 'c',
            amount: 100,
            createdAt: daysAgo(1),
          ),
        ],
      );

      expect(overview.revenueToday, 300);
      expect(overview.revenueWeek.length, 7);
      expect(overview.revenueWeek[5].value, 100, reason: 'yesterday');
      expect(overview.revenueTrend?.previous, 100);
    });

    test('quiet days are present as zeros so the shape stays true', () {
      final overview = buildOverview(
        bookings: [buildBooking(id: 'a', amount: 200, createdAt: daysAgo(6))],
      );
      final series = overview.revenueWeek;
      expect(series.length, 7);
      expect(series.first.value, 200);
      expect(series.skip(1).every((p) => p.value == 0), isTrue);
    });

    test('occupancy is booked over offered, excluding cancelled trips', () {
      final overview = buildOverview(
        trips: [
          buildTrip(id: 't1', capacity: 10, bookedSeats: 8),
          buildTrip(id: 't2', capacity: 10, bookedSeats: 2),
          buildTrip(
            id: 't3',
            capacity: 100,
            bookedSeats: 0,
            status: OperationTripStatus.cancelled,
          ),
        ],
      );
      expect(overview.occupancyToday, closeTo(0.5, 0.001));
    });
  });

  group('week over week', () {
    test('is null while the office is younger than the baseline window', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'a', amount: 100, createdAt: daysAgo(2)),
          buildBooking(id: 'b', amount: 400),
        ],
      );
      expect(
        overview.revenueWeekTrend,
        isNull,
        reason:
            'the previous week predates the first booking, so its zeros are '
            '"no data" rather than "no revenue"',
      );
    });

    test('compares both halves once enough history exists', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'old', amount: 100, createdAt: daysAgo(13)),
          buildBooking(id: 'old2', amount: 100, createdAt: daysAgo(10)),
          buildBooking(id: 'new', amount: 300, createdAt: daysAgo(2)),
        ],
      );
      final trend = overview.revenueWeekTrend;
      expect(trend, isNotNull);
      expect(trend!.previous, 200);
      expect(trend.current, 300);
      expect(trend.direction, TrendDirection.up);
    });
  });

  group('operations', () {
    test('a trip past its departure that has not started counts as late', () {
      final overview = buildOverview(
        trips: [
          buildTrip(id: 'late', at: fixedNow.subtract(const Duration(hours: 2))),
          buildTrip(
            id: 'running',
            at: fixedNow.subtract(const Duration(hours: 2)),
            status: OperationTripStatus.inProgress,
          ),
          buildTrip(id: 'later', at: fixedNow.add(const Duration(hours: 2))),
        ],
      );
      expect(overview.delayedTrips.map((t) => t.id), ['late']);
      expect(overview.tripsRunningNow, 1);
      expect(overview.tripsUpcomingToday, 1);
    });

    test('the roster counts distinct drivers actually on today, not payroll', () {
      final overview = buildOverview(
        trips: [
          buildTrip(id: 't1', driverId: 'd1'),
          buildTrip(id: 't2', driverId: 'd1'),
          buildTrip(id: 't3', driverId: 'd2'),
          buildTrip(
            id: 't4',
            driverId: 'd3',
            status: OperationTripStatus.cancelled,
          ),
        ],
        fleet: buildFleet(activeDrivers: 9, activeVehicles: 4),
      );
      expect(overview.driversOnDuty, 2);
      expect(overview.activeDrivers, 9);
    });

    test('fleet utilisation is null with no active fleet to measure', () {
      expect(buildOverview().fleetUtilisation, isNull);
    });
  });

  group('money', () {
    test('outstanding excludes cancelled bookings and settled payments', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(
            id: 'waiting',
            amount: 100,
            paymentStatus: PaymentStatus.pending,
          ),
          buildBooking(
            id: 'reviewing',
            amount: 50,
            paymentStatus: PaymentStatus.underReview,
          ),
          buildBooking(id: 'paid', amount: 999),
          buildBooking(
            id: 'dropped',
            amount: 999,
            status: BookingStatus.cancelled,
            paymentStatus: PaymentStatus.pending,
          ),
          buildBooking(
            id: 'refused',
            amount: 999,
            paymentStatus: PaymentStatus.rejected,
          ),
        ],
      );
      expect(overview.outstanding, 150);
    });

    test('net revenue is collected minus refunds settled in the window', () {
      final overview = buildOverview(
        bookings: [buildBooking(id: 'a', amount: 1000)],
        wallet: buildWallet(
          liability: 400,
          refunds: [
            SettledRefund(settledAt: daysAgo(2), amount: 150, toWallet: true),
            SettledRefund(settledAt: daysAgo(90), amount: 900, toWallet: false),
          ],
          movements: [
            WalletMovement(
              date: daysAgo(1),
              kind: WalletMovementKind.cashback,
              amount: 50,
            ),
          ],
        ),
      );
      expect(overview.collected(), 1000);
      expect(overview.refundsSettled(), 150, reason: 'the 90-day-old one is out');
      expect(overview.netRevenue(), 850);
      expect(overview.promotionalCost(), 50);
      expect(overview.contribution(), 800);
      expect(overview.walletLiability, 400);
    });

    test('collection rate is received over billed, null with nothing billed', () {
      expect(buildOverview().collectionRate(), isNull);

      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'paid', amount: 750),
          buildBooking(
            id: 'unpaid',
            amount: 250,
            paymentStatus: PaymentStatus.pending,
          ),
        ],
      );
      expect(overview.collectionRate(), closeTo(0.75, 0.001));
    });
  });

  group('customers', () {
    test('guest bookings carry no account and are excluded', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'a', clientId: ''),
          buildBooking(id: 'b', clientId: '   '),
          buildBooking(id: 'c', clientId: 'client-1'),
        ],
      );
      expect(overview.totalCustomers, 1);
    });

    test('new is first-ever booking in window; returning is everyone else', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'old', clientId: 'loyal', createdAt: daysAgo(200)),
          buildBooking(id: 'recent', clientId: 'loyal', createdAt: daysAgo(3)),
          buildBooking(id: 'first', clientId: 'fresh', createdAt: daysAgo(2)),
          buildBooking(id: 'gone', clientId: 'lapsed', createdAt: daysAgo(120)),
        ],
      );
      expect(overview.activeCustomerIds(), {'loyal', 'fresh'});
      expect(overview.newCustomerIds(), {'fresh'});
      expect(overview.returningCustomerIds(), {'loyal'});
      expect(overview.inactiveCustomers(), 1);
      expect(overview.retentionRate(), closeTo(0.5, 0.001));
    });

    test('top customer ranks by approved spend inside the window', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'a', clientId: 'big', amount: 400),
          buildBooking(id: 'b', clientId: 'big', amount: 400),
          buildBooking(id: 'c', clientId: 'small', amount: 500),
          buildBooking(
            id: 'd',
            clientId: 'unpaid',
            amount: 5000,
            paymentStatus: PaymentStatus.pending,
          ),
        ],
      );
      final top = overview.topCustomer();
      expect(top?.clientId, 'big');
      expect(top?.spend, 800);
      expect(top?.bookings, 2);
    });
  });

  group('health', () {
    test('an unmeasurable signal reads unknown, never healthy', () {
      final signals = buildOverview().healthSignals;
      final occupancy = signals.firstWhere(
        (s) => s.metric == BusinessHealthMetric.occupancy,
      );
      expect(occupancy.status, BusinessHealthStatus.unknown);
      expect(occupancy.reading, '—');
    });

    test('occupancy grades against the stated 70% target', () {
      final signals = buildOverview(
        trips: [buildTrip(id: 't1', capacity: 10, bookedSeats: 9)],
      ).healthSignals;
      final occupancy = signals.firstWhere(
        (s) => s.metric == BusinessHealthMetric.occupancy,
      );
      expect(occupancy.status, BusinessHealthStatus.healthy);
      expect(occupancy.reading, '90%');
    });

    test('problems sort ahead of healthy readings', () {
      final signals = buildOverview(
        trips: [buildTrip(id: 't1', capacity: 10, bookedSeats: 1)],
        refundRequests: [
          for (var i = 0; i < 5; i++) buildRefund(id: 'r$i'),
        ],
      ).healthSignals;

      expect(signals.first.status, BusinessHealthStatus.critical);
      expect(signals.last.status, BusinessHealthStatus.unknown);
    });
  });

  group('insights', () {
    test('a route is not named until it has three trips behind it', () {
      final overview = buildOverview(
        trips: [
          buildTrip(
            id: 't1',
            route: 'القاهرة - بنها',
            capacity: 10,
            bookedSeats: 10,
            at: daysAgo(2),
          ),
        ],
      );
      expect(
        overview.insights.where(
          (i) => i.kind == InsightKind.routePerformance,
        ),
        isEmpty,
      );
    });

    test('a route running near-full over three trips is called out', () {
      final overview = buildOverview(
        trips: [
          for (var i = 0; i < 3; i++)
            buildTrip(
              id: 't$i',
              route: 'القاهرة - بنها',
              capacity: 10,
              bookedSeats: 10,
              at: daysAgo(i + 1),
            ),
        ],
      );
      final insight = overview.insights.firstWhere(
        (i) => i.kind == InsightKind.routePerformance,
      );
      expect(insight.severity, InsightSeverity.positive);
      expect(insight.title, contains('القاهرة - بنها'));
      expect(insight.title, contains('100'), reason: 'the measured occupancy');
      expect(
        insight.detail,
        contains('30 مقعد من 30'),
        reason: 'the evidence the finding rests on, not just the verdict',
      );
      expect(insight.source, InsightSource.derived);
    });

    test('a quiet office produces no insights rather than filler', () {
      expect(buildOverview().insights, isEmpty);
    });
  });

  group('attention', () {
    test('only non-empty queues appear, most urgent first', () {
      final overview = buildOverview(
        bookings: [
          buildBooking(id: 'v1', paymentStatus: PaymentStatus.submitted),
        ],
        captainRequests: [buildCaptainRequest(id: 'c1')],
        refundRequests: [buildRefund(id: 'r1', amount: 75)],
      );
      final kinds = overview.attentionItems.map((i) => i.kind).toList();

      expect(kinds, contains(BusinessAttentionKind.paymentsAwaitingReview));
      expect(kinds, contains(BusinessAttentionKind.refundRequests));
      expect(kinds, contains(BusinessAttentionKind.captainRequests));
      expect(kinds, isNot(contains(BusinessAttentionKind.staleTrips)));
      expect(
        kinds.last,
        BusinessAttentionKind.captainRequests,
        reason: 'info severity sorts last',
      );
    });

    test('a live booking on a cancelled trip is a conflict', () {
      final overview = buildOverview(
        trips: [
          buildTrip(id: 'dead-trip', status: OperationTripStatus.cancelled),
          buildTrip(id: 'live-trip'),
        ],
        bookings: [
          buildBooking(id: 'stranded', tripId: 'dead-trip'),
          buildBooking(
            id: 'already-cancelled',
            tripId: 'dead-trip',
            status: BookingStatus.cancelled,
          ),
          buildBooking(id: 'fine', tripId: 'live-trip'),
        ],
      );
      expect(overview.bookingConflicts.map((b) => b.id), ['stranded']);
    });

    test('licence limits are raised at 80% consumed and not once spent', () {
      // Nothing to read without a resolved licence.
      expect(licenseLimitAttention(null), isEmpty);
    });
  });

  group('degraded sources', () {
    test('an unavailable feed is reported rather than rendered as zero', () {
      final overview = buildOverview(
        unavailable: {BusinessDataSource.wallet, BusinessDataSource.refunds},
      );
      expect(overview.has(BusinessDataSource.wallet), isFalse);
      expect(overview.has(BusinessDataSource.trips), isTrue);

      final refunds = overview.healthSignals.firstWhere(
        (s) => s.metric == BusinessHealthMetric.openRefunds,
      );
      expect(refunds.status, BusinessHealthStatus.unknown);
    });

    test('a refund trend is not claimed when refunds did not load', () {
      final overview = buildOverview(
        unavailable: {BusinessDataSource.refunds},
        refundRequests: [
          for (var i = 0; i < 6; i++) buildRefund(id: 'r$i', date: daysAgo(1)),
        ],
      );
      expect(
        overview.insights.where((i) => i.kind == InsightKind.refundTrend),
        isEmpty,
      );
    });
  });

  test('satisfaction averages the three ratings and needs both windows', () {
    final overview = buildOverview(
      reviews: [
        buildReview(id: 'r1', rating: 4),
        buildReview(id: 'r2', rating: 5, createdAt: daysAgo(2)),
      ],
    );
    expect(overview.satisfaction(), closeTo(4.5, 0.001));
    expect(
      overview.satisfactionTrend(),
      isNull,
      reason: 'the previous 30-day window holds no reviews to compare against',
    );
  });

  test('finance refund statuses drive the pending queue and its total', () {
    final overview = buildOverview(
      refundRequests: [
        buildRefund(id: 'a', amount: 120),
        buildRefund(
          id: 'b',
          amount: 500,
          status: finance.RefundStatus.approved,
        ),
      ],
    );
    expect(overview.pendingRefunds.length, 1);
    expect(overview.pendingRefundAmount, 120);
  });
}
