import 'package:file_saver/file_saver.dart';
import '../../domain/entities/report_entities.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_datasource.dart';
import '../services/report_export_service.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDatasource _datasource;

  const ReportsRepositoryImpl(this._datasource);

  @override
  Future<ReportData> getReportData(ReportType type, ReportFilter filter) async {
    return _datasource.getReportData(type, filter);
  }

  @override
  Future<String> exportReport(
    ReportType type,
    ReportFilter filter,
    String format,
  ) async {
    
    final data = await _datasource.getReportData(type, filter);

    final service = ReportExportService();
    final bytes = await service.generateExportBytes(data, type, format);

    final dateStr = DateTime.now().toString().substring(0, 10);
    final ext = format.toLowerCase();
    final fileName = 'تقرير_${type.label}_$dateStr';

    MimeType mimeType;
    if (ext == 'csv') {
      mimeType = MimeType.csv;
    } else if (ext == 'excel') {
      mimeType = MimeType.microsoftExcel;
    } else if (ext == 'pdf') {
      mimeType = MimeType.pdf;
    } else {
      mimeType = MimeType.other;
    }

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: ext == 'excel' ? 'xlsx' : ext,
      mimeType: mimeType,
    );

    return '$fileName.${ext == 'excel' ? 'xlsx' : ext}';
  }

  @override
  Future<List<String>> getAvailableRoutes() async =>
      _datasource.getAvailableRoutes();

  @override
  Future<List<String>> getAvailableDrivers() async =>
      _datasource.getAvailableDrivers();

  @override
  Future<List<String>> getAvailableVehicles() async =>
      _datasource.getAvailableVehicles();

  @override
  Future<List<String>> getAvailablePackages() async =>
      _datasource.getAvailablePackages();
}
