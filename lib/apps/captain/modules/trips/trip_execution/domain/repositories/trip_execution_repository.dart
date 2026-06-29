import '../entities/trip_execution_state.dart';

abstract class TripExecutionRepository {
  Future<TripExecutionStateData> startBoarding(String tripId);
  Future<TripExecutionStateData> startTrip(String tripId);
  Future<TripExecutionStateData> completeTrip(String tripId);
}
