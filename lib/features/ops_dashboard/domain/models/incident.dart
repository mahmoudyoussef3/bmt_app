class IncidentReport {
  final String id;
  final String tripId;
  final String reportedById;
  final IncidentSeverity severity;
  final String description;
  final DateTime reportedAt;
  final bool resolved;

  IncidentReport({
    required this.id,
    required this.tripId,
    required this.reportedById,
    this.severity = IncidentSeverity.medium,
    required this.description,
    DateTime? reportedAt,
    this.resolved = false,
  }) : reportedAt = reportedAt ?? DateTime.now();
}

enum IncidentSeverity { low, medium, high, critical }
