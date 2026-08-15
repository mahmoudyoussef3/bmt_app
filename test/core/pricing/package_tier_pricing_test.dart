import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';
import 'package:bmt_app/core/pricing/trip_pricing_resolver.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

/// Regression cover for the "packages are not real in the Client app" bug,
/// and its 20260815 sequel: a rider's package price used to be bucketed by
/// duration into one of 5 fixed `trip_pricing` columns, shared by every
/// office-defined package that happened to land in the same bucket. Prices
/// now live per package_id in `trip_package_prices`, and
/// `PackageTierPricing` only supplies a *default suggestion* — these tests
/// pin the suggestion curve and the resolver reading real per-package prices
/// back through the exact code the Client booking wizard uses.
void main() {
  const fare = 100.0;
  const anchors = [5, 10, 22, 66];

  group('PackageTierPricing.priceForRideCount', () {
    test('a package always costs more than a single ride', () {
      for (final rides in anchors) {
        expect(
          PackageTierPricing.priceForRideCount(rides, fare),
          greaterThan(fare),
          reason: '$rides rides must not be priced like a single ride',
        );
      }
    });

    test('a package always beats paying per ride', () {
      for (final rides in anchors) {
        final price = PackageTierPricing.priceForRideCount(rides, fare);
        expect(price, lessThan(fare * rides));
      }
    });

    test('reproduces the historical catalog multipliers exactly', () {
      expect(PackageTierPricing.priceForRideCount(5, fare), 350); // 3.5x
      expect(PackageTierPricing.priceForRideCount(10, fare), 375); // 3.75x
      expect(PackageTierPricing.priceForRideCount(22, fare), 400); // 4x
      expect(PackageTierPricing.priceForRideCount(66, fare), 450); // 4.5x
    });

    test('reproduces the pricing the operator configured by hand', () {
      // The one trip priced through the Trip Pricing tab: 200 -> 700/750/800/900.
      expect(PackageTierPricing.priceForRideCount(5, 200), 700);
      expect(PackageTierPricing.priceForRideCount(10, 200), 750);
      expect(PackageTierPricing.priceForRideCount(22, 200), 800);
      expect(PackageTierPricing.priceForRideCount(66, 200), 900);
    });

    test('longer packages cost more in absolute terms', () {
      final prices = anchors
          .map((rides) => PackageTierPricing.priceForRideCount(rides, fare))
          .toList();
      for (var i = 1; i < prices.length; i++) {
        expect(prices[i], greaterThan(prices[i - 1]));
      }
    });

    test('an unpriced trip derives no package price', () {
      for (final rides in anchors) {
        expect(PackageTierPricing.priceForRideCount(rides, 0), 0);
      }
    });

    test('interpolates between anchors for a custom ride count', () {
      // 8 rides sits strictly between the 5-ride (3.5x) and 10-ride (3.75x)
      // anchors, so its suggested multiplier must land strictly between too.
      final price = PackageTierPricing.priceForRideCount(8, fare);
      expect(price, greaterThan(350));
      expect(price, lessThan(375));
    });

    test('extrapolates past the last anchor using its slope', () {
      // Beyond 66 rides there is no upper anchor, so the multiplier keeps
      // climbing along the 22->66 segment's slope rather than flattening.
      final beyond = PackageTierPricing.priceForRideCount(100, fare);
      expect(beyond, greaterThan(PackageTierPricing.priceForRideCount(66, fare)));
    });
  });

  group('Client reads back real per-package prices', () {
    /// A `trip_pricing` row carrying explicit per-package prices, the way
    /// the Dashboard fare panel now saves them (see
    /// `20260815091000_per_package_trip_pricing.sql`).
    final row = TripStopPairPrice(
      fromPointId: 'stop-a',
      toPointId: 'stop-b',
      oneTimePrice: fare,
      packagePrices: const {
        'pkg-five-days': 350,
        'pkg-ten-days': 375,
        'pkg-monthly': 400,
        'pkg-three-months': 450,
      },
    );

    test('a single ride resolves to the ticket price', () {
      expect(
        TripPricingResolver.oneTimeFareFor([row], 'stop-a', 'stop-b'),
        fare,
      );
    });

    test('a monthly package no longer costs the same as one ride', () {
      final monthly = TripPricingResolver.packageFareFor(
        [row],
        'stop-a',
        'stop-b',
        'pkg-monthly',
        30,
        22,
      );

      expect(monthly, isNotNull);
      expect(monthly, isNot(fare)); // the exact bug that shipped
      expect(monthly, 400);
    });

    test('each package id resolves to its own price', () {
      double? fareFor(String packageId) => TripPricingResolver.packageFareFor(
        [row],
        'stop-a',
        'stop-b',
        packageId,
        30, // any non-single-ride shape — resolution is by id, not shape
        10,
      );

      expect(fareFor('pkg-five-days'), 350);
      expect(fareFor('pkg-ten-days'), 375);
      expect(fareFor('pkg-monthly'), 400);
      expect(fareFor('pkg-three-months'), 450);

      // Distinct packages must not collapse onto one another.
      final resolved = [
        fareFor('pkg-five-days'),
        fareFor('pkg-ten-days'),
        fareFor('pkg-monthly'),
      ];
      expect(resolved.toSet(), hasLength(3));
    });

    test(
      'a single-ride package resolves to the pair\'s one-time fare instead '
      'of a trip_package_prices lookup — matches the confirm_seat_booking_v2 '
      'branch exactly, so the Client never shows a different price than the '
      'server will charge',
      () {
        final oneTime = TripPricingResolver.packageFareFor(
          [row],
          'stop-a',
          'stop-b',
          'pkg-not-priced-and-irrelevant',
          1,
          1,
        );
        expect(oneTime, fare);
      },
    );

    test('an unpriced package on this pair falls back rather than guessing', () {
      expect(
        TripPricingResolver.packageFareFor(
          [row],
          'stop-a',
          'stop-b',
          'pkg-never-priced',
          30,
          10,
        ),
        isNull,
      );
    });

    test('an unpriced stop pair falls back rather than guessing', () {
      expect(
        TripPricingResolver.packageFareFor(
          [row],
          'stop-a',
          'stop-z',
          'pkg-monthly',
          30,
          22,
        ),
        isNull,
      );
    });
  });
}
