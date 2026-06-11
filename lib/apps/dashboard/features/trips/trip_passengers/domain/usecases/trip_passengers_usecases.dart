import '../../../shared/domain/entities/operation_trip.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class UpdatePassengerUseCase {
  final TripsRepository _repository;

  const UpdatePassengerUseCase(this._repository);

  Future<OperationTrip> call(String tripId, TripPassenger passenger) {
    return _repository.updatePassenger(tripId, passenger);
  }
}

class CancelPassengerUseCase {
  final TripsRepository _repository;

  const CancelPassengerUseCase(this._repository);

  Future<OperationTrip> call(String tripId, String passengerId) {
    return _repository.cancelPassenger(tripId, passengerId);
  }
}

class MovePassengerUseCase {
  final TripsRepository _repository;

  const MovePassengerUseCase(this._repository);

  Future<OperationTrip> call(
    String tripId,
    String passengerId,
    String seatLabel,
  ) {
    return _repository.movePassenger(tripId, passengerId, seatLabel);
  }
}
