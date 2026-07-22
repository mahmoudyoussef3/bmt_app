import '../entities/office_route.dart';
import '../entities/office_summary.dart';
import '../entities/office_trip.dart';

abstract class OfficesRepository {
  /// Every active office on the marketplace, best-rated first.
  Future<List<OfficeSummary>> getOffices();

  /// The active routes one office operates.
  Future<List<OfficeRoute>> getOfficeRoutes(String officeId);

  /// The bookable departures one office is selling, soonest first.
  Future<List<OfficeTrip>> getOfficeTrips(String officeId);
}
