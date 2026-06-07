import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class GetLiveTripsUseCase {
  final LiveTripsRepository _repository;

  const GetLiveTripsUseCase(this._repository);

  Future<List<LiveTrip>> call() {
    return _repository.getLiveTrips();
  }
}
