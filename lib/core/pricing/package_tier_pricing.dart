/// The single source of truth for turning ONE base ticket fare into the
/// full `trip_pricing` tier set (one-time + the four package tiers).
///
/// Why this exists: the fare a rider pays is configured in exactly one place
/// (the trip planner's pricing panel). Every other surface — the trip-pricing
/// edit dialog, the `CreateTripUseCase` expansion, and the Client app's
/// package cards — must agree on what a "monthly" package costs for a given
/// base fare, or the Client shows prices the operator never set.
///
/// The tier columns on `trip_pricing` hold the **total** price of the package,
/// NOT a per-ride price. `TripPricingResolver` and the `confirm_seat_booking_v2`
/// RPC both charge these values as-is, so they must be totals. See
/// `20260710090000_authoritative_booking_pricing.sql`.
///
/// ## Pricing model: flat multiples of the ticket
///
/// A package is priced as a small multiple of the single-ride fare, NOT as
/// `rides x fare` — this is a subscription, deliberately far cheaper than
/// buying every ride. The multipliers below reproduce the pricing an operator
/// actually configured by hand (ticket 200 -> 700 / 750 / 800 / 900).
///
/// These are only the *defaults* that auto-fill when an operator types a
/// ticket price; every tier stays overridable per stop pair.
class PackageTierPricing {
  const PackageTierPricing._();

  /// Rides bundled into each tier, and the tier's price as a multiple of the
  /// single-ride fare. `rides` is what the rider gets; `multiplier` is what
  /// they pay — the gap between them is the subscription's value.
  static const tiers = <PackageTier>[
    PackageTier(key: 'five_days', rides: 5, multiplier: 3.5),
    PackageTier(key: 'ten_days', rides: 10, multiplier: 3.75),
    PackageTier(key: 'monthly', rides: 22, multiplier: 4.0),
    PackageTier(key: 'three_months', rides: 66, multiplier: 4.5),
  ];

  static PackageTier get fiveDays => tiers[0];
  static PackageTier get tenDays => tiers[1];
  static PackageTier get monthly => tiers[2];
  static PackageTier get threeMonths => tiers[3];

  /// The default total price for [tier] given a [baseFare] for one ride.
  static double priceFor(PackageTier tier, double baseFare) {
    if (baseFare <= 0) return 0;
    return tier.totalFor(baseFare);
  }

  /// Whether these tiers look like the flat/unconfigured pricing the old
  /// `CreateTripUseCase` wrote (every tier equal to the one-time fare), which
  /// made a monthly subscription cost the same as a single ride in the Client.
  static bool isFlat({
    required double oneTime,
    required double fiveDays,
    required double tenDays,
    required double monthly,
    required double threeMonths,
  }) {
    return oneTime == fiveDays &&
        oneTime == tenDays &&
        oneTime == monthly &&
        oneTime == threeMonths;
  }
}

/// One package tier: the rides it bundles and its price as a multiple of the
/// single-ride fare.
class PackageTier {
  const PackageTier({
    required this.key,
    required this.rides,
    required this.multiplier,
  });

  /// Stable identifier matching the `trip_pricing` column stem
  /// (`five_days` -> `five_days_price`).
  final String key;

  /// Number of rides the package bundles.
  final int rides;

  /// Package price as a multiple of one ticket (4.0 = four tickets).
  final double multiplier;

  /// What the same rides would cost bought one at a time.
  double regularTotalFor(double baseFare) => baseFare * rides;

  /// The package total the rider actually pays.
  double totalFor(double baseFare) => baseFare * multiplier;

  /// What the rider saves versus buying each ride separately.
  double savingsFor(double baseFare) =>
      regularTotalFor(baseFare) - totalFor(baseFare);
}
