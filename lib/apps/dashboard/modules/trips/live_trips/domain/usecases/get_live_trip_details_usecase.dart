import '../entities/live_trip.dart';
import '../repositories/live_trips_repository.dart';

class GetLiveTripDetailsUseCase {
  final LiveTripsRepository _repository;

  const GetLiveTripDetailsUseCase(this._repository);

  Future<LiveTrip> call(String tripId) =>
      _repository.getLiveTripDetails(tripId);
}
