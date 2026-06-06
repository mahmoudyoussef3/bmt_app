enum AssignedTripStatus { scheduled, boarding, inProgress, completed }

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
  });

  final String id;
  final String route;
  final String vehicleNumber;
  final String plateNumber;
  final DateTime departureTime;
  final DateTime expectedArrivalTime;
  final List<String> stops;
  final int passengerCount;
  final int boardedCount;
  final AssignedTripStatus status;

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
    );
  }
}
