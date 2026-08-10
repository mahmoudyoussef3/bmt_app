import '../entities/route_details.dart';
import '../entities/route_summary.dart';

abstract class RoutesDirectoryRepository {
  /// Every active route on the marketplace, across every active office.
  Future<List<RouteSummary>> getRoutes();

  /// One route's full record, including its ordered stop list.
  Future<RouteDetails> getRouteDetails(String routeId);
}
