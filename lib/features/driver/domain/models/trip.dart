import 'package:bmt_app/features/driver/domain/models/vehicle.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';

enum TripStatus { scheduled, boarding, inProgress, completed, cancelled }

class Trip {
  final String id;
  final String route;
  final DateTime departure;
  final DateTime expectedArrival;
  final Vehicle vehicle;
  final List<String> stops;
  final List<Passenger> passengers;
  TripStatus status;

  Trip({
    required this.id,
    required this.route,
    required this.departure,
    required this.expectedArrival,
    required this.vehicle,
    required this.stops,
    required this.passengers,
    this.status = TripStatus.scheduled,
  });
}
