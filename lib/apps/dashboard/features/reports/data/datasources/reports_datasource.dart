import '../../domain/entities/report_entities.dart';

abstract class ReportsDatasource {
  Future<ReportData> getReportData(ReportType type, ReportFilter filter);
  Future<List<String>> getAvailableRoutes();
  Future<List<String>> getAvailableDrivers();
  Future<List<String>> getAvailableVehicles();
  Future<List<String>> getAvailablePackages();
}
