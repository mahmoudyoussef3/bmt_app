import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetTripDetailsUseCase {
  const GetTripDetailsUseCase(this._repository);

  final TripsRepository _repository;

  Future<TripData?> call(String id) {
    return _repository.getTripById(id);
  }
}
