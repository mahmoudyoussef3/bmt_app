/// A single `trip_pricing` row: the Dashboard-configured fare for one
/// specific pickup -> dropoff stop pair on one trip.
///
/// Mirrors `trip_pricing` (see DATABASE_SCHEMA.md): unique per
/// (trip_id, from_point_id, to_point_id). `oneTimePrice` is the regular
/// per-ride fare; the other fields are the package/subscription tiers for
/// that same pair.
class TripStopPairPrice {
  const TripStopPairPrice({
    required this.fromPointId,
    required this.toPointId,
    required this.oneTimePrice,
    this.packagePrices = const {},
    this.currency = 'EGP',
    this.isActive = true,
  });

  final String fromPointId;
  final String toPointId;
  final double oneTimePrice;

  /// This stop pair's price for each of the office's multi-ride packages,
  /// keyed by `transport_packages.id`. Backs `trip_package_prices`.
  final Map<String, double> packagePrices;
  final String currency;
  final bool isActive;

  bool matchesPair(String fromPointId, String toPointId) =>
      this.fromPointId == fromPointId && this.toPointId == toPointId;
}
