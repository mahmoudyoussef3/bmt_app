import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class MarkRoutePointArrivedUseCase {
  final LiveTripsRepository _repository;

  const MarkRoutePointArrivedUseCase(this._repository);

  Future<LiveTrip> call(String tripId, String pointId) =>
      _repository.markPointArrived(tripId, pointId);
}
