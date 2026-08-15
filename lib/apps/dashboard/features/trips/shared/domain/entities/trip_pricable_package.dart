/// One of the office's own `transport_packages` rows, trimmed to what the
/// trip fare editor needs to render a price field for it.
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

  const TripPricablePackage({
    required this.id,
    required this.name,
    required this.rideCount,
    required this.durationDays,
  });
}
