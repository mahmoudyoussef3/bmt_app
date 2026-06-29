import '../repositories/live_trips_repository.dart';

class WatchLiveTripsUseCase {
  const WatchLiveTripsUseCase(this._repository);

  final LiveTripsRepository _repository;

  Stream<void> call() => _repository.watchTripStatusChanges();
}
