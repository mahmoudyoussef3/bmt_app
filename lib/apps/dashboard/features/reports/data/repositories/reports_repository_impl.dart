import '../../domain/entities/report_entities.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDatasource _datasource;

  const ReportsRepositoryImpl(this._datasource);

  @override
  Future<ReportData> getReportData(ReportType type, ReportFilter filter) async {
    return _datasource.getReportData(type, filter);
  }

  @override
  Future<String> exportReport(ReportType type, ReportFilter filter, String format) async {
    // Mock export generation: delay slightly to simulate building the file
    await Future.delayed(const Duration(milliseconds: 600));
    final dateStr = DateTime.now().toString().substring(0, 10);
    final ext = format.toLowerCase();
    return 'تقرير_${type.label}_$dateStr.$ext';
  }

  @override
  Future<List<String>> getAvailableRoutes() async => _datasource.getAvailableRoutes();

  @override
  Future<List<String>> getAvailableDrivers() async => _datasource.getAvailableDrivers();

  @override
  Future<List<String>> getAvailableVehicles() async => _datasource.getAvailableVehicles();

  @override
  Future<List<String>> getAvailablePackages() async => _datasource.getAvailablePackages();
}
