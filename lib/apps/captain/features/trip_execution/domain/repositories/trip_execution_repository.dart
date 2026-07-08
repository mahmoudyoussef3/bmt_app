import '../entities/trip_execution_state.dart';

abstract class TripExecutionRepository {
  Future<TripExecutionStateData> startBoarding(String tripId);
  Future<TripExecutionStateData> startTrip(String tripId);
  Future<TripExecutionStateData> completeTrip(String tripId);
  Stream<TripExecutionStatus> watchTripStatus(String tripId);

  /// Records that the vehicle has arrived at route point [pointId] by
  /// inserting the canonical `trip_events` arrival marker — the same
  /// convention the Dashboard uses, so Dashboard, Client, and Captain all
  /// agree on trip progress.
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  });
}
