import '../../../shared/domain/entities/operation_trip.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class UpdateSeatStateUseCase {
  final TripsRepository _repository;

  const UpdateSeatStateUseCase(this._repository);

  Future<OperationTrip> call(String tripId, String seatId, TripSeatState state) {
    return _repository.updateSeatState(tripId, seatId, state);
  }
}
