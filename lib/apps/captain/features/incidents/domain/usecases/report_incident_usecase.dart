import '../entities/incident_report.dart';
import '../repositories/incident_repository.dart';

class ReportIncidentUseCase {
  const ReportIncidentUseCase(this._repository);

  final IncidentRepository _repository;

  Future<IncidentReport> call(IncidentReport report) {
    return _repository.reportIncident(report);
  }
}
