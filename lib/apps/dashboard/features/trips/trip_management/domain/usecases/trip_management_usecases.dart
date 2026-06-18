import '../../../shared/domain/entities/operation_trip.dart';
import '../repositories/trips_repository.dart';

class GetOperationTripsUseCase {
  final TripsRepository _repository;

  const GetOperationTripsUseCase(this._repository);

  Future<List<OperationTrip>> call() {
    return _repository.getTrips();
  }
}

class GetTripDetailsUseCase {
  final TripsRepository _repository;

  const GetTripDetailsUseCase(this._repository);

  Future<OperationTrip> call(String tripId) {
    return _repository.getTripById(tripId);
  }
}

class UpdateTripStatusUseCase {
  final TripsRepository _repository;

  const UpdateTripStatusUseCase(this._repository);

  Future<OperationTrip> call(String tripId, OperationTripStatus status) {
    return _repository.updateTripStatus(tripId, status);
  }
}

class UpdateTripInfoUseCase {
  final TripsRepository _repository;

  const UpdateTripInfoUseCase(this._repository);

  Future<OperationTrip> call(OperationTrip trip) {
    return _repository.updateTripInfo(trip);
  }
}

class DeleteTripUseCase {
  final TripsRepository _repository;

  const DeleteTripUseCase(this._repository);

  Future<void> call(String tripId) {
    return _repository.deleteTrip(tripId);
  }
}
