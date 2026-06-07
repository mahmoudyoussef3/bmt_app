import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class CreateRouteUseCase {
  final RoutesRepository _repository;

  const CreateRouteUseCase(this._repository);

  Future<OperationRoute> call(OperationRoute route) {
    return _repository.createRoute(route);
  }
}
