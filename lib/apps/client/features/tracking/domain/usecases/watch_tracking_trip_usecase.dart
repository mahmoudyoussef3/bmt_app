import '../repositories/tracking_repository.dart';

class WatchTrackingTripUseCase {
  const WatchTrackingTripUseCase(this._repository);

  final TrackingRepository _repository;

  Stream<void> call(String tripId) => _repository.watchTripChanges(tripId);
}
