import '../entities/incident_report.dart';

abstract class IncidentRepository {
  Future<IncidentReport> reportIncident(IncidentReport report);
}
