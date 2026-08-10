import '../entities/route_summary.dart';
import '../repositories/routes_directory_repository.dart';

class GetRoutesUseCase {
  const GetRoutesUseCase(this._repository);

  final RoutesDirectoryRepository _repository;

  Future<List<RouteSummary>> call() => _repository.getRoutes();
}
