import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The analytics layer's judgement calls — the derivations that turn raw counts
/// into a claim about an office.
///
/// The numbers themselves come from SQL and are covered by
/// `supabase/tests/platform_office_analytics_regression.sql`. What is tested
/// here is everything the client decides on top of them: when an office counts
/// as idle rather than new, which flags fire, what order they arrive in, and
/// the several places where "zero" and "unknown" must not be confused.
void main() {
  PlatformOffice office({
    String id = 'office-a',
    String name = 'مكتب الإسكندرية',
    String status = 'active',
    String listingStatus = 'listed',
    DateTime? createdAt,
  }) => PlatformOffice(
    id: id,
    name: name,
    slug: 'alex',
    description: 'نقل يومي',
    serviceAreas: const ['الإسكندرية'],
    status: status,
    listingStatus: listingStatus,
    rating: 0,
    ratingsCount: 0,
    operators: 1,
    drivers: 1,
    routes: 1,
    createdAt: createdAt,
  );

  PlatformOfficeMetrics metrics({
    String officeId = 'office-a',
    int totalBookings = 10,
    int recentBookings = 5,
    int cancelledBookings = 0,
    int confirmedBookings = 5,
    int upcomingTrips = 3,
    int staleTrips = 0,
    int paymentsAwaitingReview = 0,
    double paymentsAwaitingAmount = 0,
    int openTickets = 0,
    int pendingCaptainRequests = 0,
    int reviewsTotal = 0,
    int activeAdmins = 1,
    int seatsOffered = 0,
    int seatsSold = 0,
    double revenueTotal = 0,
    double revenueRecent = 0,
    double? averageRating,
    DateTime? lastBookingAt,
  }) => PlatformOfficeMetrics(
    officeId: officeId,
    totalBookings: totalBookings,
    recentBookings: recentBookings,
    cancelledBookings: cancelledBookings,
    confirmedBookings: confirmedBookings,
    upcomingTrips: upcomingTrips,
    staleTrips: staleTrips,
    paymentsAwaitingReview: paymentsAwaitingReview,
    paymentsAwaitingAmount: paymentsAwaitingAmount,
    openTickets: openTickets,
    pendingCaptainRequests: pendingCaptainRequests,
    reviewsTotal: reviewsTotal,
    activeAdmins: activeAdmins,
    seatsOffered: seatsOffered,
    seatsSold: seatsSold,
    revenueTotal: revenueTotal,
    revenueRecent: revenueRecent,
    averageRating: averageRating,
    lastBookingAt: lastBookingAt,
  );

  PlatformAnalytics analytics(
    List<PlatformOfficeMetrics> rows, {
    PlatformTotals totals = const PlatformTotals(),
    int windowDays = 30,
  }) => PlatformAnalytics(
    windowDays: windowDays,
    totals: totals,
    trend: const [],
    offices: {for (final row in rows) row.officeId: row},
  );

  group('activity level', () {
    test('an office with bookings in the window is active', () {
      expect(metrics(recentBookings: 3).activityLevel, ActivityLevel.active);
    });

    test('an office that traded before but not lately is idle', () {
      final m = metrics(totalBookings: 10, recentBookings: 0);
      expect(m.activityLevel, ActivityLevel.idle);
      expect(m.isIdle, isTrue);
    });

    // The distinction the whole screen turns on: "stopped" and "never started"
    // are different problems with different remedies, and a lifetime count
    // cannot tell them apart.
    test('an office that never traded is not idle, it never started', () {
      final m = metrics(totalBookings: 0, recentBookings: 0);
      expect(m.activityLevel, ActivityLevel.never);
      expect(m.isIdle, isFalse);
      expect(m.hasNeverTraded, isTrue);
    });
  });

  group('occupancy', () {
    test('is the share of offered seats that sold', () {
      expect(metrics(seatsOffered: 40, seatsSold: 10).occupancyLabel, '25%');
    });

    // Nothing offered is not the same as nothing sold. 0% would accuse the
    // office of failing to sell seats it never put on sale.
    test('is null when no seats were offered at all', () {
      final m = metrics(seatsOffered: 0, seatsSold: 0);
      expect(m.occupancyRate, isNull);
      expect(m.occupancyLabel, isNull);
    });
  });

  group('derived money', () {
    test('average booking value divides revenue by confirmed bookings', () {
      final m = metrics(revenueTotal: 1000, confirmedBookings: 4);
      expect(m.averageBookingValue, 250);
    });

    test('average booking value is null with no confirmed bookings', () {
      expect(metrics(confirmedBookings: 0).averageBookingValue, isNull);
    });

    test(
      'money is formatted whole when whole, and to two places otherwise',
      () {
        expect(metrics(revenueRecent: 1500).revenueRecentLabel, '1500 ج.م');
        expect(
          metrics(revenueRecent: 1500.5).revenueRecentLabel,
          '1500.50 ج.م',
        );
      },
    );

    test('cancellation rate is lifetime, not windowed', () {
      final m = metrics(totalBookings: 20, cancelledBookings: 5);
      expect(m.cancellationRate, 0.25);
      expect(m.cancellationRateLabel, '25%');
    });

    test(
      'cancellation rate of an office with no bookings is zero, not NaN',
      () {
        expect(
          metrics(totalBookings: 0, cancelledBookings: 0).cancellationRate,
          0,
        );
      },
    );
  });

  group('attention flags', () {
    test('an office with no active admin raises a critical flag', () {
      final flags = analytics([
        metrics(activeAdmins: 0),
      ]).attentionFor([office()]);

      expect(
        flags.any(
          (f) =>
              f.severity == AttentionSeverity.critical &&
              f.title.contains('مسؤول'),
        ),
        isTrue,
      );
    });

    // The flag that justifies the whole feature: nothing on the office card
    // says this, and every passenger who opens the office hits a dead end.
    test(
      'a listed office with no upcoming trips is a marketplace dead end',
      () {
        final flags = analytics([
          metrics(upcomingTrips: 0),
        ]).attentionFor([office(listingStatus: 'listed')]);

        expect(
          flags.any(
            (f) =>
                f.severity == AttentionSeverity.critical &&
                f.title.contains('رحلات قادمة'),
          ),
          isTrue,
        );
      },
    );

    test('an unlisted office with no upcoming trips raises nothing — no '
        'passenger can reach it', () {
      final flags = analytics([
        metrics(upcomingTrips: 0),
      ]).attentionFor([office(listingStatus: 'draft')]);

      expect(flags.any((f) => f.title.contains('رحلات قادمة')), isFalse);
    });

    test('unreviewed payments are flagged with their count and amount', () {
      final flags = analytics([
        metrics(paymentsAwaitingReview: 19, paymentsAwaitingAmount: 970),
      ]).attentionFor([office()]);

      final flag = flags.firstWhere((f) => f.title.contains('مدفوعات'));
      expect(flag.detail, contains('19'));
      expect(flag.detail, contains('970 ج.م'));
    });

    test('an idle office is flagged with how long it has been silent', () {
      final flags = analytics([
        metrics(
          totalBookings: 10,
          recentBookings: 0,
          lastBookingAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
      ]).attentionFor([office()]);

      final flag = flags.firstWhere((f) => f.title.contains('توقف'));
      expect(flag.detail, contains('45'));
    });

    // A newly created office has no bookings by definition. Flagging it on day
    // one would put every onboarding into the queue and train the operator to
    // ignore it.
    test('a brand-new office with no bookings is not flagged as unstarted', () {
      final flags = analytics([metrics(totalBookings: 0, recentBookings: 0)])
          .attentionFor([
            office(createdAt: DateTime.now().subtract(const Duration(days: 2))),
          ]);

      expect(flags.any((f) => f.title.contains('لم يبدأ')), isFalse);
    });

    test('an office a week old with no bookings is flagged as unstarted', () {
      final flags = analytics([metrics(totalBookings: 0, recentBookings: 0)])
          .attentionFor([
            office(
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          ]);

      expect(flags.any((f) => f.title.contains('لم يبدأ')), isTrue);
    });

    test('a low rating is flagged only once there are enough reviews', () {
      final few = analytics([
        metrics(averageRating: 1.5, reviewsTotal: 2),
      ]).attentionFor([office()]);
      expect(few.any((f) => f.title.contains('تقييم')), isFalse);

      final enough = analytics([
        metrics(averageRating: 1.5, reviewsTotal: 8),
      ]).attentionFor([office()]);
      expect(enough.any((f) => f.title.contains('تقييم')), isTrue);
    });

    test('a high cancellation rate needs a meaningful sample too', () {
      final tiny = analytics([
        metrics(totalBookings: 2, cancelledBookings: 2),
      ]).attentionFor([office()]);
      expect(tiny.any((f) => f.title.contains('إلغاء')), isFalse);

      final real = analytics([
        metrics(totalBookings: 20, cancelledBookings: 10),
      ]).attentionFor([office()]);
      expect(real.any((f) => f.title.contains('إلغاء')), isTrue);
    });

    test('a healthy office raises nothing at all', () {
      final flags = analytics([
        metrics(averageRating: 4.8, reviewsTotal: 10),
      ]).attentionFor([office()]);

      expect(flags, isEmpty);
    });

    test('flags arrive worst-first', () {
      final flags = analytics([
        metrics(
          activeAdmins: 0,
          upcomingTrips: 3,
          openTickets: 2,
          paymentsAwaitingReview: 1,
          paymentsAwaitingAmount: 50,
        ),
      ]).attentionFor([office()]);

      final ranks = flags.map((f) => f.severity.rank).toList();
      expect(ranks, orderedEquals([...ranks]..sort((a, b) => b.compareTo(a))));
      expect(flags.first.severity, AttentionSeverity.critical);
    });

    // An office the analytics call did not cover is unmeasured, not healthy.
    // Reporting zeros for it would quietly assert it has no problems.
    test('an office with no metrics row raises nothing rather than zeros', () {
      final flags = analytics([]).attentionFor([office()]);
      expect(flags, isEmpty);
    });

    test(
      'flags from several offices are all present and each names its own',
      () {
        final flags =
            analytics([
              metrics(officeId: 'a', activeAdmins: 0),
              metrics(officeId: 'b', staleTrips: 4),
            ]).attentionFor([
              office(id: 'a', name: 'أ'),
              office(id: 'b', name: 'ب'),
            ]);

        expect(flags.map((f) => f.officeName).toSet(), {'أ', 'ب'});
        expect(
          flags.firstWhere((f) => f.officeId == 'b').detail,
          contains('4'),
        );
      },
    );
  });

  group('platform totals', () {
    test('occupancy is null when the platform offered no seats', () {
      expect(const PlatformTotals().occupancyRate, isNull);
    });

    test('awaiting-listing is the gap between active and listed', () {
      const totals = PlatformTotals(active: 7, listed: 3);
      expect(totals.awaitingListing, 4);
    });
  });

  group('sorting', () {
    final offices = [
      office(id: 'a', name: 'أ'),
      office(id: 'b', name: 'ب'),
      office(id: 'c', name: 'ج'),
    ];

    final rows = {
      'a': metrics(officeId: 'a', revenueRecent: 100, recentBookings: 1),
      'b': metrics(officeId: 'b', revenueRecent: 900, recentBookings: 9),
      'c': metrics(officeId: 'c', revenueRecent: 500, recentBookings: 5),
    };

    test('revenue orders by the window revenue, descending', () {
      const filter = PlatformOfficeFilter(sort: PlatformOfficeSort.revenue);
      expect(
        filter.apply(offices, metrics: rows).map((o) => o.id),
        orderedEquals(['b', 'c', 'a']),
      );
    });

    test('activity orders by bookings in the window', () {
      const filter = PlatformOfficeFilter(sort: PlatformOfficeSort.activity);
      expect(
        filter.apply(offices, metrics: rows).map((o) => o.id),
        orderedEquals(['b', 'c', 'a']),
      );
    });

    // Longest silence first — but an office that never traded has no silence to
    // measure, and burying the real churn under it would defeat the sort.
    test('idle puts the longest-silent first and the never-traded last', () {
      final withIdle = {
        'a': metrics(
          officeId: 'a',
          lastBookingAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        'b': metrics(
          officeId: 'b',
          lastBookingAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        'c': metrics(officeId: 'c', totalBookings: 0, lastBookingAt: null),
      };

      const filter = PlatformOfficeFilter(sort: PlatformOfficeSort.idle);
      expect(
        filter.apply(offices, metrics: withIdle).map((o) => o.id),
        orderedEquals(['b', 'a', 'c']),
      );
    });

    // Without analytics the metric sorts have nothing to sort on. Falling back
    // to the server's order beats inventing one that looks deliberate.
    test('a metric sort without metrics keeps the incoming order', () {
      const filter = PlatformOfficeFilter(sort: PlatformOfficeSort.revenue);
      expect(
        filter.apply(offices).map((o) => o.id),
        orderedEquals(['a', 'b', 'c']),
      );
    });

    test('the default sort leaves the server order untouched', () {
      const filter = PlatformOfficeFilter();
      expect(filter.isEmpty, isTrue);
      expect(
        filter.apply(offices, metrics: rows).map((o) => o.id),
        orderedEquals(['a', 'b', 'c']),
      );
    });

    test(
      'a non-default sort makes the filter non-empty, so it can be cleared',
      () {
        const filter = PlatformOfficeFilter(sort: PlatformOfficeSort.name);
        expect(filter.isEmpty, isFalse);
      },
    );
  });

  group('activity facet', () {
    final offices = [office(id: 'a'), office(id: 'b'), office(id: 'c')];
    final rows = {
      'a': metrics(officeId: 'a', recentBookings: 5),
      'b': metrics(officeId: 'b', totalBookings: 3, recentBookings: 0),
      'c': metrics(officeId: 'c', totalBookings: 0, recentBookings: 0),
    };

    test('filters to trading offices', () {
      const filter = PlatformOfficeFilter(activity: ActivityLevel.active);
      expect(filter.apply(offices, metrics: rows).map((o) => o.id), ['a']);
    });

    test('filters to offices that have gone quiet', () {
      const filter = PlatformOfficeFilter(activity: ActivityLevel.idle);
      expect(filter.apply(offices, metrics: rows).map((o) => o.id), ['b']);
    });

    // Not-yet-measured is not the same as not-matching. Hiding an office
    // because its numbers are in flight would report a fact we do not have.
    test('an unmeasured office stays visible rather than being excluded', () {
      const filter = PlatformOfficeFilter(activity: ActivityLevel.active);
      expect(filter.apply(offices).map((o) => o.id), ['a', 'b', 'c']);
    });

    test('composes with the status facets', () {
      final mixed = [
        office(id: 'a', status: 'active'),
        office(id: 'b', status: 'suspended'),
      ];
      const filter = PlatformOfficeFilter(
        status: 'active',
        activity: ActivityLevel.active,
      );
      expect(
        filter
            .apply(mixed, metrics: {'a': rows['a']!, 'b': rows['a']!})
            .map((o) => o.id),
        ['a'],
      );
    });
  });
}
