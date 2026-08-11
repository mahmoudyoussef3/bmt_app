import '../entities/trip_execution_state.dart';

abstract class TripExecutionRepository {
  Future<TripExecutionStateData> startBoarding(String tripId);
  Future<TripExecutionStateData> startTrip(String tripId);
  Future<TripExecutionStateData> completeTrip(String tripId);

  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  });

  /// Reports reaching the trip's next un-departed station. There is no station
  /// argument: the server resolves which one, so the captain cannot mark an
  /// arbitrary stop completed.
  Future<void> markStationArrived(String tripId);
}
