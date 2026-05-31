class Trip {
  final String id;
  final String routeId;
  final String driverId;
  final TripStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  Trip({
    required this.id,
    required this.routeId,
    required this.driverId,
    this.status = TripStatus.scheduled,
    DateTime? startedAt,
    this.endedAt,
  }) : startedAt = startedAt ?? DateTime.now();
}

enum TripStatus { scheduled, active, completed, cancelled, delayed }
