import '../../domain/entities/incident_report.dart';
import '../models/incident_report_model.dart';

abstract class IncidentDatasource {
  Future<IncidentReportModel> reportIncident(IncidentReport report);
}
