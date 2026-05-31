class InspectionReport {
  final String id;
  final Map<String, bool> checks;
  final bool passed;
  final DateTime timestamp;

  InspectionReport({
    required this.id,
    required this.checks,
    required this.passed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
