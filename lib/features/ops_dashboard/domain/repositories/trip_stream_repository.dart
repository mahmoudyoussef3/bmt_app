import '../models/trip_update.dart';

abstract class TripStreamRepository {
  /// Subscribe to trip updates stream (state, progress, location)
  Stream<TripUpdate> subscribeTripUpdates();

  /// Command to modify trip (mocked)
  Future<void> cancelTrip(String tripId);
  Future<void> completeTrip(String tripId);
  Future<void> reassignDriver(String tripId, String driverId);
}
