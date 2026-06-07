import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class UpdateRouteUseCase {
  final RoutesRepository _repository;

  const UpdateRouteUseCase(this._repository);

  Future<OperationRoute> call(OperationRoute route) {
    return _repository.updateRoute(route);
  }
}
