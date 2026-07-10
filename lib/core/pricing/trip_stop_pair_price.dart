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
    required this.fiveDaysPrice,
    required this.tenDaysPrice,
    required this.monthlyPrice,
    required this.threeMonthsPrice,
    this.currency = 'EGP',
    this.isActive = true,
  });

  final String fromPointId;
  final String toPointId;
  final double oneTimePrice;
  final double fiveDaysPrice;
  final double tenDaysPrice;
  final double monthlyPrice;
  final double threeMonthsPrice;
  final String currency;
  final bool isActive;

  bool matchesPair(String fromPointId, String toPointId) =>
      this.fromPointId == fromPointId && this.toPointId == toPointId;
}
