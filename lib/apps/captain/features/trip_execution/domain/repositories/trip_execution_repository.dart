import '../entities/trip_execution_state.dart';

abstract class TripExecutionRepository {
  Future<TripExecutionStateData> startBoarding(String tripId);
  Future<TripExecutionStateData> startTrip(String tripId);
  Future<TripExecutionStateData> completeTrip(String tripId);

  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  });

  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  });
}
