import '../repositories/captain_trip_repository.dart';

class WatchAssignedTripsUseCase {
  const WatchAssignedTripsUseCase(this._repository);

  final CaptainTripRepository _repository;

  Stream<void> call() => _repository.watchTripUpdates();
}
