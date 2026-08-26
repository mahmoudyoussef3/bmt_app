/// One station on this trip's corridor, as snapshotted onto the trip itself
/// (`trip_route_points`) rather than read off the route.
///
/// The snapshot is what the trip actually runs: an office can re-time or
/// re-order a route after a trip is published, and the rider's ticket must keep
/// describing the journey they bought.
///
/// [arrivalOffset] / [departureOffset] are `"HH:MM"` **durations measured from
/// the route's start**, not clock times — the same contract
/// `parse_route_offset` states in the database. Resolving one against the
/// trip's departure time is a presentation concern, so nothing here pretends to
/// know what o'clock a stop happens at.
class TripStop {
  const TripStop({
    required this.id,
    required this.name,
    required this.order,
    this.stationId = '',
    this.arrivalOffset = '',
    this.departureOffset = '',
    this.latitude,
    this.longitude,
    this.isBoarding = false,
    this.isDropoff = false,
  });

  /// `trip_route_points.id` — this trip's own copy of the station.
  final String id;

  /// `trip_route_points.route_point_id` — the route's master station id, and
  /// the id a booking's pickup/drop-off point is expressed in.
  final String stationId;

  final String name;

  /// Running order along the corridor (`point_order`).
  final int order;

  final String arrivalOffset;
  final String departureOffset;

  final double? latitude;
  final double? longitude;

  /// Where this rider gets on / off. Both false on a stop that belongs to
  /// somebody else's journey.
  final bool isBoarding;
  final bool isDropoff;

  bool get isMine => isBoarding || isDropoff;

  bool get hasCoordinates => latitude != null && longitude != null;
}
