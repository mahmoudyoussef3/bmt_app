import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class UpdateRouteStationUseCase {
  final RoutesRepository _repository;

  const UpdateRouteStationUseCase(this._repository);

  Future<OperationRoute> call(String routeId, RouteStation station) {
    return _repository.updateStation(routeId, station);
  }
}
