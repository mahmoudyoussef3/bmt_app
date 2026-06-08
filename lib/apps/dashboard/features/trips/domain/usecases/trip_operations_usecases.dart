import '../entities/operation_trip.dart';
import '../repositories/trips_repository.dart';

class CreateOperationTripUseCase {
  final TripsRepository _repository;

  const CreateOperationTripUseCase(this._repository);

  Future<OperationTrip> call(CreateTripInput input) {
    return _repository.createTrip(input);
  }
}

class UpdateTripInfoUseCase {
  final TripsRepository _repository;

  const UpdateTripInfoUseCase(this._repository);

  Future<OperationTrip> call(OperationTrip trip) {
    return _repository.updateTripInfo(trip);
  }
}

class UpdateTripPassengerUseCase {
  final TripsRepository _repository;

  const UpdateTripPassengerUseCase(this._repository);

  Future<OperationTrip> call(String tripId, TripPassenger passenger) {
    return _repository.updatePassenger(tripId, passenger);
  }
}

class CancelTripPassengerUseCase {
  final TripsRepository _repository;

  const CancelTripPassengerUseCase(this._repository);

  Future<OperationTrip> call(String tripId, String passengerId) {
    return _repository.cancelPassenger(tripId, passengerId);
  }
}

class MoveTripPassengerUseCase {
  final TripsRepository _repository;

  const MoveTripPassengerUseCase(this._repository);

  Future<OperationTrip> call(
    String tripId,
    String passengerId,
    String seatLabel,
  ) {
    return _repository.movePassenger(tripId, passengerId, seatLabel);
  }
}
