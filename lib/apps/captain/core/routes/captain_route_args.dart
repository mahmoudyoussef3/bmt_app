import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';

class ReportIncidentArgs {
  const ReportIncidentArgs({
    required this.tripId,
    this.initialType = IncidentType.delay,
  });

  final String tripId;

  final IncidentType initialType;
}
