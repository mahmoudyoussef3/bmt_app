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
    this.packageNotes = const {},
    this.currency = 'EGP',
    this.isActive = true,
  });

  final String fromPointId;
  final String toPointId;
  final double oneTimePrice;

  /// This stop pair's price for each package the trip sells, keyed by
  /// `transport_packages.id`. Backs `trip_package_prices`. The keys are also
  /// the trip's package *menu*: a package with no entry here is not on offer
  /// for this trip at all — see
  /// `20260820100000_trip_scoped_packages.sql`.
  final Map<String, double> packagePrices;

  /// The office's optional note for each of those packages on this trip,
  /// shown to the rider under the package in the booking wizard. Backs
  /// `trip_package_prices.note`; a package with no note is absent.
  final Map<String, String> packageNotes;
  final String currency;
  final bool isActive;

  bool matchesPair(String fromPointId, String toPointId) =>
      this.fromPointId == fromPointId && this.toPointId == toPointId;
}
