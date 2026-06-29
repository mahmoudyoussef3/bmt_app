import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class ReorderRouteStationsUseCase {
  final RoutesRepository _repository;

  const ReorderRouteStationsUseCase(this._repository);

  Future<OperationRoute> call(String routeId, int oldIndex, int newIndex) {
    return _repository.reorderStations(routeId, oldIndex, newIndex);
  }
}
