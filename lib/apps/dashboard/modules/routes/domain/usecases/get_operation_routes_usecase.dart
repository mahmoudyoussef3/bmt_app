import '../entities/operation_route.dart';
import '../repositories/routes_repository.dart';

class GetOperationRoutesUseCase {
  final RoutesRepository _repository;

  const GetOperationRoutesUseCase(this._repository);

  Future<List<OperationRoute>> call() {
    return _repository.getRoutes();
  }
}
