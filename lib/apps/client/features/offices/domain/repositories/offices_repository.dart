import '../entities/office_route.dart';
import '../entities/office_summary.dart';

abstract class OfficesRepository {
  /// Every active office on the marketplace, best-rated first.
  Future<List<OfficeSummary>> getOffices();

  /// The active routes one office operates.
  Future<List<OfficeRoute>> getOfficeRoutes(String officeId);
}
