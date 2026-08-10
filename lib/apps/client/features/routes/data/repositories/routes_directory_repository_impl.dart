import '../../domain/entities/route_details.dart';
import '../../domain/entities/route_summary.dart';
import '../../domain/repositories/routes_directory_repository.dart';
import '../datasources/routes_directory_datasource.dart';

class RoutesDirectoryRepositoryImpl implements RoutesDirectoryRepository {
  const RoutesDirectoryRepositoryImpl(this._datasource);

  final RoutesDirectoryDatasource _datasource;

  @override
  Future<List<RouteSummary>> getRoutes() => _datasource.fetchRoutes();

  @override
  Future<RouteDetails> getRouteDetails(String routeId) =>
      _datasource.fetchRouteDetails(routeId);
}
