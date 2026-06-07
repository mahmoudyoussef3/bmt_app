import '../entities/operation_trip.dart';
import '../repositories/trips_repository.dart';

class UpdateTripStatusUseCase {
  final TripsRepository _repository;

  const UpdateTripStatusUseCase(this._repository);

  Future<OperationTrip> call(String tripId, OperationTripStatus status) {
    return _repository.updateTripStatus(tripId, status);
  }
}
