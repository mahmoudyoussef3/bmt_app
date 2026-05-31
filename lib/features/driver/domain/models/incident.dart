class Incident {
  final String id;
  final String type;
  final String description;
  final int severity; // 1..5
  final DateTime timestamp;

  Incident({
    required this.id,
    required this.type,
    required this.description,
    required this.severity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
