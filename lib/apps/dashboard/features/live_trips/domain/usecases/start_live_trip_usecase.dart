import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class StartLiveTripUseCase {
  final LiveTripsRepository _repository;

  const StartLiveTripUseCase(this._repository);

  Future<LiveTrip> call(String tripId) => _repository.startTrip(tripId);
}
