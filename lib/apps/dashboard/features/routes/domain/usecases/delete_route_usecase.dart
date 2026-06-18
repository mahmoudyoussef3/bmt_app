import '../repositories/routes_repository.dart';

class DeleteRouteUseCase {
  final RoutesRepository _repository;

  const DeleteRouteUseCase(this._repository);

  Future<void> call(String routeId) {
    return _repository.deleteRoute(routeId);
  }
}
