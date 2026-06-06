enum IncidentType {
  passengerIssue,
  vehicleIssue,
  delay,
  emergency,
  routeBlockage,
  other,
}

class IncidentReport {
  const IncidentReport({
    required this.tripId,
    required this.type,
    required this.description,
  });

  final String tripId;
  final IncidentType type;
  final String description;
}
