import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class AddRouteStationUseCase {
  final RoutesRepository _repository;

  const AddRouteStationUseCase(this._repository);

  Future<OperationRoute> call(String routeId, RouteStation station) {
    return _repository.addStation(routeId, station);
  }
}
