import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class MarkRoutePointCompletedUseCase {
  final LiveTripsRepository _repository;

  const MarkRoutePointCompletedUseCase(this._repository);

  Future<LiveTrip> call(String tripId, String pointId) =>
      _repository.markPointCompleted(tripId, pointId);
}
