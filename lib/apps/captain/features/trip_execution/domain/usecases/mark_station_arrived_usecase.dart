import '../repositories/trip_execution_repository.dart';

class MarkStationArrivedUseCase {
  const MarkStationArrivedUseCase(this._repository);

  final TripExecutionRepository _repository;

  Future<void> call({
    required String tripId,
    required String pointId,
    required String pointName,
  }) => _repository.markStationArrived(
    tripId: tripId,
    pointId: pointId,
    pointName: pointName,
  );
}
