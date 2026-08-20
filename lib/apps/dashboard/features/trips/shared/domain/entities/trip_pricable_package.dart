/// One `transport_packages` row the trip fare editor can price, trimmed to
/// what it needs to render a field for it.
///
/// Deliberately excludes single-ride-shaped packages (`durationDays <= 1`
/// and `rideCount <= 1`) — that shape is the trip's base "ticket price"
/// field (`trip_pricing.one_time_price`), not a subscription tier with its
/// own row in `trip_package_prices`.
class TripPricablePackage {
  final String id;
  final String name;
  final int rideCount;
  final int durationDays;

  /// True when this package was created for one trip only (`trip_id` set),
  /// rather than being an office catalog package offered as a template on
  /// every trip. See `20260820100000_trip_scoped_packages.sql`.
  final bool isTripScoped;

  const TripPricablePackage({
    required this.id,
    required this.name,
    required this.rideCount,
    required this.durationDays,
    this.isTripScoped = false,
  });
}
