import '../models/office_route_model.dart';
import '../models/office_summary_model.dart';
import '../models/office_trip_model.dart';

abstract class OfficesDatasource {
  Future<List<OfficeSummaryModel>> fetchOffices();

  Future<List<OfficeRouteModel>> fetchOfficeRoutes(String officeId);

  Future<List<OfficeTripModel>> fetchOfficeTrips(String officeId);
}
