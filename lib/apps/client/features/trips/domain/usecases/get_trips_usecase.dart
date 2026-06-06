import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetTripsUseCase {
  const GetTripsUseCase(this._repository);

  final TripsRepository _repository;

  Future<List<TripData>> call() {
    return _repository.getTrips();
  }
}
