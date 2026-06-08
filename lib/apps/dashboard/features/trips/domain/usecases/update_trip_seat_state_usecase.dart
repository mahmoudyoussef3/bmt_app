import '../entities/operation_trip.dart';
import '../repositories/trips_repository.dart';

class UpdateTripSeatStateUseCase {
  final TripsRepository _repository;

  const UpdateTripSeatStateUseCase(this._repository);

  Future<OperationTrip> call(
    String tripId,
    String seatId,
    TripSeatState state,
  ) {
    return _repository.updateSeatState(tripId, seatId, state);
  }
}
