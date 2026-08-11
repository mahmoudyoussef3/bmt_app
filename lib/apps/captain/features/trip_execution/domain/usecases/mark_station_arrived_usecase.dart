import '../repositories/trip_execution_repository.dart';

class MarkStationArrivedUseCase {
  const MarkStationArrivedUseCase(this._repository);

  final TripExecutionRepository _repository;

  Future<void> call(String tripId) => _repository.markStationArrived(tripId);
}
