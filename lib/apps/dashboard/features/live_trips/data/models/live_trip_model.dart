import '../../domain/entities/live_trip.dart';

class LiveTripModel extends LiveTrip {
  const LiveTripModel({
    required super.id,
    required super.route,
    required super.driver,
    required super.driverStatus,
    required super.vehicle,
    required super.passengersCount,
    required super.progress,
    required super.eta,
    required super.currentStation,
    required super.nextStation,
    required super.timeline,
    required super.alerts,
  });
}
