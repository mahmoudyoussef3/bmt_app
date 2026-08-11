import '../entities/station_passenger.dart';
import '../repositories/station_progress_repository.dart';

class GetStationPassengersUseCase {
  const GetStationPassengersUseCase(this._repository);

  final StationProgressRepository _repository;

  Future<List<StationPassenger>> call({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) => _repository.passengersAt(
    tripId: tripId,
    routePointId: routePointId,
    pointName: pointName,
  );
}
