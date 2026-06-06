import '../entities/passenger.dart';
import '../repositories/passenger_manifest_repository.dart';

class GetTripPassengersUseCase {
  const GetTripPassengersUseCase(this._repository);

  final PassengerManifestRepository _repository;

  Future<List<Passenger>> call(String tripId) {
    return _repository.getTripPassengers(tripId);
  }
}
