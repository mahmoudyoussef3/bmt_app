import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class CompleteLiveTripUseCase {
  final LiveTripsRepository _repository;

  const CompleteLiveTripUseCase(this._repository);

  Future<LiveTrip> call(String tripId) => _repository.completeTrip(tripId);
}
