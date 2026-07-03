import '../entities/location_sharing_state.dart';
import '../repositories/location_repository.dart';

class SendLocationUpdateUseCase {
  const SendLocationUpdateUseCase(this._repository);

  final LocationRepository _repository;

  Future<LocationUpdateData> call(String tripId) {
    return _repository.sendLocation(tripId);
  }
}
