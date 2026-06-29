import '../entities/trip_execution_state.dart';
import '../repositories/trip_execution_repository.dart';

class StartBoardingUseCase {
  const StartBoardingUseCase(this._repository);

  final TripExecutionRepository _repository;

  Future<TripExecutionStateData> call(String tripId) =>
      _repository.startBoarding(tripId);
}
