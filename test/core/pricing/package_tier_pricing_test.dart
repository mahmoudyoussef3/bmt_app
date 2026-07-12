import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';
import 'package:bmt_app/core/pricing/trip_pricing_resolver.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

/// Regression cover for the "packages are not real in the Client app" bug.
///
/// The Dashboard used to expand the planner's single ticket price into
/// `trip_pricing` by copying it into ALL FIVE tier columns, so a monthly
/// subscription resolved to the price of one ride. These tests pin the
/// derivation and then read it back through the exact resolver the Client
/// booking wizard uses.
void main() {
  const fare = 100.0;

  group('PackageTierPricing derivation', () {
    test('a package always costs more than a single ride', () {
      for (final tier in PackageTierPricing.tiers) {
        expect(
          PackageTierPricing.priceFor(tier, fare),
          greaterThan(fare),
          reason: '${tier.key} must not be priced like a single ride',
        );
      }
    });

    test('a package always beats paying per ride', () {
      for (final tier in PackageTierPricing.tiers) {
        final package = PackageTierPricing.priceFor(tier, fare);
        expect(
          package,
          lessThan(tier.regularTotalFor(fare)),
          reason: '${tier.key} must save the rider money',
        );
        expect(tier.savingsFor(fare), greaterThan(0));
      }
    });

    test('tiers are flat multiples of the ticket price', () {
      expect(PackageTierPricing.priceFor(PackageTierPricing.fiveDays, fare),
          350); // 3.5x
      expect(PackageTierPricing.priceFor(PackageTierPricing.tenDays, fare),
          375); // 3.75x
      expect(PackageTierPricing.priceFor(PackageTierPricing.monthly, fare),
          400); // 4x
      expect(PackageTierPricing.priceFor(PackageTierPricing.threeMonths, fare),
          450); // 4.5x
    });

    test('reproduces the pricing the operator configured by hand', () {
      // The one trip priced through the Trip Pricing tab: 200 -> 700/750/800/900.
      expect(PackageTierPricing.priceFor(PackageTierPricing.fiveDays, 200), 700);
      expect(PackageTierPricing.priceFor(PackageTierPricing.tenDays, 200), 750);
      expect(PackageTierPricing.priceFor(PackageTierPricing.monthly, 200), 800);
      expect(
        PackageTierPricing.priceFor(PackageTierPricing.threeMonths, 200),
        900,
      );
    });

    test('longer packages cost more in absolute terms', () {
      final prices = PackageTierPricing.tiers
          .map((tier) => PackageTierPricing.priceFor(tier, fare))
          .toList();
      for (var i = 1; i < prices.length; i++) {
        expect(prices[i], greaterThan(prices[i - 1]));
      }
    });

    test('an unpriced trip derives no package price', () {
      for (final tier in PackageTierPricing.tiers) {
        expect(PackageTierPricing.priceFor(tier, 0), 0);
      }
    });

    test('detects the flat pricing the old writer produced', () {
      expect(
        PackageTierPricing.isFlat(
          oneTime: fare,
          fiveDays: fare,
          tenDays: fare,
          monthly: fare,
          threeMonths: fare,
        ),
        isTrue,
      );
      expect(
        PackageTierPricing.isFlat(
          oneTime: fare,
          fiveDays: 450,
          tenDays: 850,
          monthly: 1760,
          threeMonths: 4950,
        ),
        isFalse,
      );
    });
  });

  group('Client reads back the derived tiers', () {
    /// A `trip_pricing` row written the way the fixed CreateTripUseCase writes
    /// it, for the exact stop pair a rider picked.
    final row = TripStopPairPrice(
      fromPointId: 'stop-a',
      toPointId: 'stop-b',
      oneTimePrice: fare,
      fiveDaysPrice:
          PackageTierPricing.priceFor(PackageTierPricing.fiveDays, fare),
      tenDaysPrice:
          PackageTierPricing.priceFor(PackageTierPricing.tenDays, fare),
      monthlyPrice:
          PackageTierPricing.priceFor(PackageTierPricing.monthly, fare),
      threeMonthsPrice:
          PackageTierPricing.priceFor(PackageTierPricing.threeMonths, fare),
    );

    test('a single ride resolves to the ticket price', () {
      expect(
        TripPricingResolver.oneTimeFareFor([row], 'stop-a', 'stop-b'),
        fare,
      );
    });

    test('a monthly package no longer costs the same as one ride', () {
      // 30-day / 22-ride subscription -> monthly tier.
      final monthly = TripPricingResolver.packageFareFor(
        [row],
        'stop-a',
        'stop-b',
        30,
        22,
      );

      expect(monthly, isNotNull);
      expect(monthly, isNot(fare)); // the exact bug that shipped
      expect(monthly, 400);
    });

    test('each package duration maps to its own tier', () {
      double? fareFor(int days, int rides) => TripPricingResolver.packageFareFor(
            [row],
            'stop-a',
            'stop-b',
            days,
            rides,
          );

      expect(fareFor(1, 1), fare); // single ride
      expect(fareFor(5, 5), 350); // work week
      expect(fareFor(10, 10), 375); // two work weeks
      expect(fareFor(30, 22), 400); // work month
      expect(fareFor(90, 66), 450); // three months

      // Distinct tiers must not collapse onto one another.
      final resolved = [fareFor(5, 5), fareFor(10, 10), fareFor(30, 22)];
      expect(resolved.toSet(), hasLength(3));
    });

    test('an unpriced stop pair falls back rather than guessing', () {
      expect(
        TripPricingResolver.packageFareFor([row], 'stop-a', 'stop-z', 30, 22),
        isNull,
      );
    });
  });
}
