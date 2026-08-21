import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_insight.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_profile.dart';

import 'customers_test_fixtures.dart';

/// ملخص العميل must be deterministic and checkable. Every chip is a function of
/// fields the database recorded; these tests pin the thresholds so a future
/// edit cannot quietly turn a fact into a guess.
void main() {
  List<String> labelsFor(CustomerProfile profile) =>
      CustomerInsights.of(profile, testNow).map((i) => i.label).toList();

  group('activity', () {
    test('recent activity reads as نشط', () {
      final labels = labelsFor(
        profileFixture(
          metrics: metricsFixture(
            lastBookingAt: testNow.subtract(const Duration(days: 3)),
          ),
        ),
      );

      expect(labels, contains('عميل نشط'));
    });

    test('90 days of silence names the number of days', () {
      final labels = labelsFor(
        profileFixture(
          metrics: metricsFixture(
            lastBookingAt: testNow.subtract(const Duration(days: 120)),
          ),
        ),
      );

      expect(labels, contains('خامل منذ 120 يوماً'));
    });

    test('the 31–89 day band claims neither', () {
      // Deliberately not complements: a customer last seen 45 days ago is
      // neither active nor dormant, and inventing a verdict would be a claim
      // the data does not support.
      final labels = labelsFor(
        profileFixture(
          metrics: metricsFixture(
            lastBookingAt: testNow.subtract(const Duration(days: 45)),
          ),
        ),
      );

      expect(labels, isNot(contains('عميل نشط')));
      expect(labels.any((l) => l.startsWith('خامل')), isFalse);
    });

    test('a customer with no activity at all says so', () {
      final labels = labelsFor(
        profileFixture(metrics: const CustomerMetrics()),
      );

      expect(labels, contains('لا يوجد نشاط مع المكتب'));
    });
  });

  group('subscription', () {
    test('a current subscription reads as ساري', () {
      final labels = labelsFor(
        profileFixture(activeSubscription: subscriptionFixture()),
      );

      expect(labels, contains('لديه اشتراك ساري'));
    });

    test('an imminent expiry names the days left instead', () {
      final labels = labelsFor(
        profileFixture(
          activeSubscription: subscriptionFixture(
            endDate: testNow.add(const Duration(days: 3)),
          ),
        ),
      );

      expect(labels, contains('اشتراكه ينتهي خلال 3 أيام'));
      expect(labels, isNot(contains('لديه اشتراك ساري')));
    });

    test('an unused package is flagged', () {
      final labels = labelsFor(
        profileFixture(
          activeSubscription: subscriptionFixture(tripsUsed: 0, tripsCount: 10),
        ),
      );

      expect(labels, contains('لم يستخدم أي رحلة من اشتراكه'));
    });

    test('a package with no allowance is not flagged as unused', () {
      // trips_count = 0 is real in this data. "Used none of zero" is not a
      // finding, it is a division that does not exist.
      final labels = labelsFor(
        profileFixture(
          activeSubscription: subscriptionFixture(
            tripsUsed: 0,
            tripsCount: 0,
            usagePercent: null,
          ),
        ),
      );

      expect(labels, isNot(contains('لم يستخدم أي رحلة من اشتراكه')));
    });
  });

  group('upcoming trip', () {
    test('today and tomorrow are named, not dated', () {
      expect(
        labelsFor(
          profileFixture(metrics: metricsFixture(nextTripDate: testNow)),
        ),
        contains('لديه رحلة اليوم'),
      );
      expect(
        labelsFor(
          profileFixture(
            metrics: metricsFixture(
              nextTripDate: testNow.add(const Duration(days: 1)),
            ),
          ),
        ),
        contains('لديه رحلة غداً'),
      );
    });
  });

  group('behaviour flags', () {
    test('a high cancellation rate reports the share and the counts', () {
      final labels = labelsFor(
        profileFixture(
          metrics: metricsFixture(bookingsTotal: 10, bookingsCancelled: 4),
        ),
      );

      // The denominator travels with the percentage on purpose: "٤٠٪" alone
      // invites the reader to supply their own.
      expect(labels, contains('ألغى 40٪ من حجوزاته (4 من 10)'));
    });

    test('a small sample is never given a cancellation rate', () {
      final labels = labelsFor(
        profileFixture(
          metrics: metricsFixture(bookingsTotal: 2, bookingsCancelled: 1),
        ),
      );

      expect(labels.any((l) => l.startsWith('ألغى')), isFalse);
    });

    test('repeated no-shows are flagged, a single one is not', () {
      expect(
        labelsFor(profileFixture(metrics: metricsFixture(noShowCount: 3))),
        contains('لم يحضر 3 من الرحلات'),
      );
      expect(
        labelsFor(
          profileFixture(metrics: metricsFixture(noShowCount: 1)),
        ).any((l) => l.startsWith('لم يحضر')),
        isFalse,
      );
    });

    test('a wallet balance is mentioned, an absent wallet is not', () {
      expect(
        labelsFor(profileFixture(metrics: metricsFixture(walletBalance: 250))),
        contains('لديه رصيد في المحفظة'),
      );
      expect(
        labelsFor(profileFixture(metrics: metricsFixture(walletBalance: null))),
        isNot(contains('لديه رصيد في المحفظة')),
      );
      expect(
        labelsFor(profileFixture(metrics: metricsFixture(walletBalance: 0))),
        isNot(contains('لديه رصيد في المحفظة')),
      );
    });

    test('open complaints are surfaced', () {
      expect(
        labelsFor(profileFixture(metrics: metricsFixture(ticketsOpen: 2))),
        contains('لديه 2 شكوى مفتوحة'),
      );
    });
  });

  group('derived metrics', () {
    test('cancellation rate needs at least four bookings', () {
      expect(metricsFixture(bookingsTotal: 3).cancellationRate, isNull);
      expect(
        metricsFixture(bookingsTotal: 4, bookingsCancelled: 1).cancellationRate,
        0.25,
      );
    });

    test('boarding rate is null until a manifest reaches a verdict', () {
      expect(
        metricsFixture(boardedCount: 0, noShowCount: 0).boardingRate,
        isNull,
        reason: 'a reserved manifest has said nothing about attendance',
      );
      expect(
        metricsFixture(boardedCount: 3, noShowCount: 1).boardingRate,
        0.75,
      );
    });

    test('last activity is the newest of the three streams', () {
      final metrics = CustomerMetrics(
        lastBookingAt: DateTime(2026, 8, 1),
        lastPaymentAt: DateTime(2026, 8, 15),
        lastWalletAt: DateTime(2026, 8, 9),
      );

      expect(metrics.lastActivityAt, DateTime(2026, 8, 15));
    });

    test('usage clamps past 100% rather than overflowing its track', () {
      // A package consumed past its allowance is a real row; a bar wider than
      // its track is a rendering bug.
      expect(subscriptionFixture(usagePercent: 140).usageFraction, 1.0);
      expect(subscriptionFixture(usagePercent: null).usageFraction, isNull);
    });
  });
}
