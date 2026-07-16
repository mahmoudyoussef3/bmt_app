import '../entities/trip_execution_state.dart';

abstract class TripExecutionRepository {
  Future<TripExecutionStateData> startBoarding(String tripId);
  Future<TripExecutionStateData> startTrip(String tripId);
  Future<TripExecutionStateData> completeTrip(String tripId);

  /// Watches status, boarded/passenger counts, and confirmed station arrivals
  /// for [tripId], re-emitting whenever any of them change. [routePointCount]
  /// clamps the arrival count to the trip's actual station list (see
  /// `stationArrivalFloor`).
  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  });

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
