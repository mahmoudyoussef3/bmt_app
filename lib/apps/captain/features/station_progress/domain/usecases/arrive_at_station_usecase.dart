import '../repositories/station_progress_repository.dart';

class ArriveAtStationUseCase {
  const ArriveAtStationUseCase(this._repository);

  final StationProgressRepository _repository;

  Future<void> call(String tripId) => _repository.arriveAtStation(tripId);
}
