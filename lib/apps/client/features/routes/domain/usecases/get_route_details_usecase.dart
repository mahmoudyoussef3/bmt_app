import '../entities/route_details.dart';
import '../repositories/routes_directory_repository.dart';

class GetRouteDetailsUseCase {
  const GetRouteDetailsUseCase(this._repository);

  final RoutesDirectoryRepository _repository;

  Future<RouteDetails> call(String routeId) =>
      _repository.getRouteDetails(routeId);
}
