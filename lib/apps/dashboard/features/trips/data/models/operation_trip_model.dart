import '../../domain/entities/operation_trip.dart';

class OperationTripModel extends OperationTrip {
  const OperationTripModel({
    required super.id,
    required super.route,
    required super.routePoints,
    required super.driver,
    required super.vehicle,
    required super.date,
    required super.departure,
    required super.arrival,
    required super.status,
    required super.capacity,
    required super.seats,
    required super.passengers,
    required super.events,
    required super.notes,
  });

  factory OperationTripModel.fromEntity(OperationTrip trip) {
    return OperationTripModel(
      id: trip.id,
      route: trip.route,
      routePoints: trip.routePoints,
      driver: trip.driver,
      vehicle: trip.vehicle,
      date: trip.date,
      departure: trip.departure,
      arrival: trip.arrival,
      status: trip.status,
      capacity: trip.capacity,
      seats: trip.seats,
      passengers: trip.passengers,
      events: trip.events,
      notes: trip.notes,
    );
  }
}
