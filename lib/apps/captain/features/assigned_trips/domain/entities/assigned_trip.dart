enum AssignedTripStatus { scheduled, boarding, inProgress, completed }

/// A route station as scheduled for one trip, carrying the `trip_route_points`
/// row id so the captain app can report an arrival against the exact point
/// (see `trip_events` title `'وصول محطة'` convention).
class AssignedTripStop {
  const AssignedTripStop({required this.id, required this.name});

  final String id;
  final String name;
}

class AssignedTrip {
  const AssignedTrip({
    required this.id,
    required this.route,
    required this.vehicleNumber,
    required this.plateNumber,
    required this.departureTime,
    required this.expectedArrivalTime,
    required this.stops,
    required this.passengerCount,
    required this.boardedCount,
    this.status = AssignedTripStatus.scheduled,
    this.arrivedStationsCount = 0,
  });

  final String id;
  final String route;
  final String vehicleNumber;
  final String plateNumber;
  final DateTime departureTime;
  final DateTime expectedArrivalTime;
  final List<AssignedTripStop> stops;
  final int passengerCount;
  final int boardedCount;
  final AssignedTripStatus status;

  /// How many leading stations the captain has already reported arrived
  /// (the shared `trip_events` arrival floor, clamped to `stops.length`).
  /// Lets the trip execution screen resume at the right next station
  /// instead of resetting to the first one on every reopen.
  final int arrivedStationsCount;

  AssignedTrip copyWith({AssignedTripStatus? status, int? boardedCount}) {
    return AssignedTrip(
      id: id,
      route: route,
      vehicleNumber: vehicleNumber,
      plateNumber: plateNumber,
      departureTime: departureTime,
      expectedArrivalTime: expectedArrivalTime,
      stops: stops,
      passengerCount: passengerCount,
      boardedCount: boardedCount ?? this.boardedCount,
      status: status ?? this.status,
      arrivedStationsCount: arrivedStationsCount,
    );
  }
}
