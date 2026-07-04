import '../entities/trip_execution_state.dart';
import '../repositories/trip_execution_repository.dart';

class WatchTripExecutionStatusUseCase {
  const WatchTripExecutionStatusUseCase(this._repository);

  final TripExecutionRepository _repository;

  Stream<TripExecutionStatus> call(String tripId) =>
      _repository.watchTripStatus(tripId);
}
