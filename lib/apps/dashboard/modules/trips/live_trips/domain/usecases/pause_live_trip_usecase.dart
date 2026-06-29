import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class PauseLiveTripUseCase {
  final LiveTripsRepository _repository;

  const PauseLiveTripUseCase(this._repository);

  Future<LiveTrip> call(String tripId) => _repository.pauseTrip(tripId);
}
