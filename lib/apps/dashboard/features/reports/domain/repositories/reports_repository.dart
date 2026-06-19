import '../entities/report_entities.dart';

abstract class ReportsRepository {
  Future<ReportData> getReportData(ReportType type, ReportFilter filter);
  Future<String> exportReport(
    ReportType type,
    ReportFilter filter,
    String format,
  );

  Future<List<String>> getAvailableRoutes();
  Future<List<String>> getAvailableDrivers();
  Future<List<String>> getAvailableVehicles();
  Future<List<String>> getAvailablePackages();
}
