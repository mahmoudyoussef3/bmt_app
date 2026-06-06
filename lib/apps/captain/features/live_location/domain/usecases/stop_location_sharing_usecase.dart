import '../entities/location_sharing_state.dart';
import '../repositories/location_repository.dart';

class StopLocationSharingUseCase {
  const StopLocationSharingUseCase(this._repository);

  final LocationRepository _repository;

  Future<LocationSharingStateData> call(String tripId) {
    return _repository.stopSharing(tripId);
  }
}
