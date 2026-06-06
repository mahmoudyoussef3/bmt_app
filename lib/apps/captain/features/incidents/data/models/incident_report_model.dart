import '../../domain/entities/incident_report.dart';

class IncidentReportModel {
  const IncidentReportModel({
    required this.tripId,
    required this.type,
    required this.description,
  });

  final String tripId;
  final IncidentType type;
  final String description;

  IncidentReport toEntity() {
    return IncidentReport(tripId: tripId, type: type, description: description);
  }
}
