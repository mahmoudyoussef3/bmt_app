import '../repositories/passenger_manifest_repository.dart';

class WatchTripPassengersUseCase {
  const WatchTripPassengersUseCase(this._repository);

  final PassengerManifestRepository _repository;

  Stream<void> call(String tripId) => _repository.watchPassengerUpdates(tripId);
}
