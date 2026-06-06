import '../../domain/entities/incident_report.dart';
import '../models/incident_report_model.dart';

class IncidentDataSource {
  const IncidentDataSource();

  Future<IncidentReportModel> reportIncident(IncidentReport report) async {
    return IncidentReportModel(
      tripId: report.tripId,
      type: report.type,
      description: report.description,
    );
  }
}
