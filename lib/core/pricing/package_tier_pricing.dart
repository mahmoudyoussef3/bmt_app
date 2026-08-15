/// The single source of truth for suggesting a package's default price from
/// ONE base ticket fare.
///
/// Why this exists: the fare a rider pays is configured in exactly one place
/// (the trip planner's pricing panel). Every package the office has defined
/// gets its own price field there, seeded with a sensible default derived
/// from the ticket price — always overridable per stop pair, never silently
/// recomputed once the operator has touched it.
///
/// `trip_package_prices.price` holds the **total** price of the package, NOT
/// a per-ride price. `TripPricingResolver` and the `confirm_seat_booking_v2`
/// RPC both charge this value as-is, so it must be a total. See
/// `20260815091000_per_package_trip_pricing.sql`.
///
/// ## Pricing model: flat multiples of the ticket
///
/// A package is priced as a small multiple of the single-ride fare, NOT as
/// `rides x fare` — this is a subscription, deliberately far cheaper than
/// buying every ride. The curve below reproduces the pricing an operator
/// actually configured by hand for the original catalog (ticket 200 ->
/// 700 / 750 / 800 / 900 for 5/10/22/66 rides) and interpolates/extrapolates
/// it for any other ride count an office defines.
class PackageTierPricing {
  const PackageTierPricing._();

  /// Anchor points `suggestedMultiplierFor`/`priceForRideCount` interpolate
  /// across: a single ride costs exactly the base fare (1.0x), then the four
  /// multipliers hand-configured for the original catalog's 5/10/22/66-ride
  /// packages.
  static const _curve = [
    (rides: 1, multiplier: 1.0),
    (rides: 5, multiplier: 3.5),
    (rides: 10, multiplier: 3.75),
    (rides: 22, multiplier: 4.0),
    (rides: 66, multiplier: 4.5),
  ];

  /// The suggested multiplier for an office-defined package bundling
  /// [rideCount] rides — linearly interpolated between the anchor points
  /// above, and extrapolated past 66 rides using the last segment's slope.
  /// Reproduces the exact 4 historical multipliers at their exact ride
  /// counts (5/10/22/66), so offices still using the original catalog see no
  /// change; any other ride count gets a sensible in-between suggestion.
  /// Only ever a *default* — the office can override the resulting price
  /// per trip.
  static double suggestedMultiplierFor(int rideCount) {
    if (rideCount <= _curve.first.rides) return _curve.first.multiplier;
    for (var i = 0; i < _curve.length - 1; i++) {
      final lo = _curve[i];
      final hi = _curve[i + 1];
      if (rideCount <= hi.rides) {
        final t = (rideCount - lo.rides) / (hi.rides - lo.rides);
        return lo.multiplier + (hi.multiplier - lo.multiplier) * t;
      }
    }
    final lo = _curve[_curve.length - 2];
    final hi = _curve.last;
    final slope = (hi.multiplier - lo.multiplier) / (hi.rides - lo.rides);
    return hi.multiplier + slope * (rideCount - hi.rides);
  }

  /// The default total price for a package bundling [rideCount] rides, given
  /// a [baseFare] for one ride.
  static double priceForRideCount(int rideCount, double baseFare) {
    if (baseFare <= 0) return 0;
    return baseFare * suggestedMultiplierFor(rideCount);
  }
}
