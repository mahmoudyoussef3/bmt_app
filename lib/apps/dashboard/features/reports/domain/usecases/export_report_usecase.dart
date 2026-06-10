import '../entities/report_entities.dart';
import '../repositories/reports_repository.dart';

class ExportReportUseCase {
  final ReportsRepository _repository;

  const ExportReportUseCase(this._repository);

  Future<String> call(ReportType type, ReportFilter filter, String format) =>
      _repository.exportReport(type, filter, format);
}
