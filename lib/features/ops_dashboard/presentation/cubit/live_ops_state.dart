import '../../domain/models/trip_update.dart';
import '../../domain/models/driver_position.dart';
import '../../domain/models/trip_event.dart';

abstract class LiveOpsState {}

class LiveOpsLoading extends LiveOpsState {}

class LiveOpsLoaded extends LiveOpsState {
  final List<TripUpdate> trips;
  final List<DriverPosition> drivers;
  final List<TripEvent> events;

  LiveOpsLoaded({required this.trips, required this.drivers, required this.events});
}

class LiveOpsError extends LiveOpsState {
  final String message;
  LiveOpsError(this.message);
}
