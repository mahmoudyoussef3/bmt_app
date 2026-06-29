import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class SkipRoutePointUseCase {
  final LiveTripsRepository _repository;

  const SkipRoutePointUseCase(this._repository);

  Future<LiveTrip> call(String tripId, String pointId) =>
      _repository.skipPoint(tripId, pointId);
}
