import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class ResumeLiveTripUseCase {
  final LiveTripsRepository _repository;

  const ResumeLiveTripUseCase(this._repository);

  Future<LiveTrip> call(String tripId) => _repository.resumeTrip(tripId);
}
