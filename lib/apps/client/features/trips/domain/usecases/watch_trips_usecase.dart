import '../repositories/trips_repository.dart';

class WatchTripsUseCase {
  const WatchTripsUseCase(this._repository);

  final TripsRepository _repository;

  Stream<void> call() => _repository.watchTripChanges();
}
