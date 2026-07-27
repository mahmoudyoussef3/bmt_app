import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
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

  Future<OperationTrip> call(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) {
    return _repository.updateTripStatus(tripId, status, reason: reason);
  }
}

class CancelTripUseCase {
  final TripsRepository _repository;

  const CancelTripUseCase(this._repository);

  Future<OperationTrip> call(String tripId, String reason) {
    return _repository.cancelTrip(tripId, reason);
  }
}

class CloseStaleTripUseCase {
  final TripsRepository _repository;

  const CloseStaleTripUseCase(this._repository);

  Future<OperationTrip> call(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) {
    return _repository.closeStaleTrip(tripId, outcome, reason: reason);
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

/// Powers the trips list realtime refresh: emits whenever any trip's
/// status, seats, passengers, or events change in the backend.
class WatchOperationTripsUseCase {
  final TripsRepository _repository;

  const WatchOperationTripsUseCase(this._repository);

  Stream<void> call() => _repository.watchTripsChanges();
}

/// Powers the trip details workspace realtime refresh: emits whenever the
/// given trip's status, seats, passengers, or events change.
class WatchTripDetailsUseCase {
  final TripsRepository _repository;

  const WatchTripDetailsUseCase(this._repository);

  Stream<void> call(String tripId) => _repository.watchTripChanges(tripId);
}
