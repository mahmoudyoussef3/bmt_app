import '../repositories/routes_repository.dart';

class DeleteRouteStationUseCase {
  final RoutesRepository _repository;

  const DeleteRouteStationUseCase(this._repository);

  Future<void> call(String routeId, String stationId) async {
    await _repository.deleteStation(routeId, stationId);
  }
}
