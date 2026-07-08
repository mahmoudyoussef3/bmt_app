import '../../domain/entities/assigned_trip.dart';

class AssignedTripModel {
  const AssignedTripModel({
    required this.id,
    required this.route,
    required this.vehicleNumber,
    required this.plateNumber,
    required this.departureTime,
    required this.expectedArrivalTime,
    required this.stops,
    required this.passengerCount,
    required this.boardedCount,
    required this.status,
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
  final int arrivedStationsCount;

  AssignedTrip toEntity() {
    return AssignedTrip(
      id: id,
      route: route,
      vehicleNumber: vehicleNumber,
      plateNumber: plateNumber,
      departureTime: departureTime,
      expectedArrivalTime: expectedArrivalTime,
      stops: stops,
      passengerCount: passengerCount,
      boardedCount: boardedCount,
      status: status,
      arrivedStationsCount: arrivedStationsCount,
    );
  }
}
