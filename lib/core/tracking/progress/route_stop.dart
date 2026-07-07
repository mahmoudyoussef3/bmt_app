/// An ordered stop along a trip route, as snapshotted into
/// `trip_route_points` when the trip is created.
class RouteStop {
  const RouteStop({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    this.plannedArrival,
    this.plannedDeparture,
  });

  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;

  /// Scheduled arrival/departure resolved against the trip date, when the
  /// dashboard configured per-stop times.
  final DateTime? plannedArrival;
  final DateTime? plannedDeparture;

  /// (0, 0) is the placeholder for stations saved without coordinates.
  bool get hasCoordinates =>
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);
}
