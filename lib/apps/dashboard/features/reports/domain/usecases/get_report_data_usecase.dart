import '../entities/report_entities.dart';
import '../repositories/reports_repository.dart';

class GetReportDataUseCase {
  final ReportsRepository _repository;

  const GetReportDataUseCase(this._repository);

  Future<ReportData> call(ReportType type, ReportFilter filter) =>
      _repository.getReportData(type, filter);
}
