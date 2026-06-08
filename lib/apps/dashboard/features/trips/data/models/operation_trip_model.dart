import '../../domain/entities/operation_trip.dart';

class OperationTripModel extends OperationTrip {
  const OperationTripModel({
    required super.id,
    required super.route,
    required super.driver,
    required super.vehicle,
    required super.date,
    required super.departure,
    required super.arrival,
    required super.status,
    required super.seats,
    required super.passengers,
    required super.payments,
    required super.events,
    required super.notes,
  });

  factory OperationTripModel.fromEntity(OperationTrip trip) {
    return OperationTripModel(
      id: trip.id,
      route: trip.route,
      driver: trip.driver,
      vehicle: trip.vehicle,
      date: trip.date,
      departure: trip.departure,
      arrival: trip.arrival,
      status: trip.status,
      seats: trip.seats,
      passengers: trip.passengers,
      payments: trip.payments,
      events: trip.events,
      notes: trip.notes,
    );
  }
}
