import '../entities/trip_execution_state.dart';
import '../repositories/trip_execution_repository.dart';

class CompleteTripUseCase {
  const CompleteTripUseCase(this._repository);

  final TripExecutionRepository _repository;

  Future<TripExecutionStateData> call(String tripId) {
    return _repository.completeTrip(tripId);
  }
}
