import '../models/route_details_model.dart';
import '../models/route_summary_model.dart';

abstract class RoutesDirectoryDatasource {
  Future<List<RouteSummaryModel>> fetchRoutes();

  Future<RouteDetailsModel> fetchRouteDetails(String routeId);
}
