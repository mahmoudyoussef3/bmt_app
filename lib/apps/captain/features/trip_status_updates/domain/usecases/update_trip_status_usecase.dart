import '../entities/captain_trip_status.dart';
import '../repositories/trip_status_repository.dart';

class UpdateTripStatusUseCase {
  const UpdateTripStatusUseCase(this._repository);

  final TripStatusRepository _repository;

  Future<CaptainTripStatusUpdate> call(
    String tripId,
    CaptainTripStatus status,
  ) {
    return _repository.updateStatus(tripId, status);
  }
}
