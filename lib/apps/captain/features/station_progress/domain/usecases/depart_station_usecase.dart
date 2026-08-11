import '../repositories/station_progress_repository.dart';

/// Leaving a station. The gate lives in the database; this only asks.
class DepartStationUseCase {
  const DepartStationUseCase(this._repository);

  final StationProgressRepository _repository;

  Future<void> call(String tripId) => _repository.departStation(tripId);
}
