import 'position.dart';

enum EventType {
  tripStarted,
  passengerBoarded,
  delayDetected,
  incidentReported,
  sos,
}

enum EventSeverity { info, warning, critical }

class TripEvent {
  final String id;
  final String tripId;
  final EventType type;
  final EventSeverity severity;
  final String message;
  final Position? location;
  final DateTime timestamp;

  TripEvent({
    required this.id,
    required this.tripId,
    required this.type,
    required this.severity,
    required this.message,
    this.location,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
