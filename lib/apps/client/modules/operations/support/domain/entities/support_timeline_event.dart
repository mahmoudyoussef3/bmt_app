class SupportTimelineEvent {
  const SupportTimelineEvent({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.description,
    required this.eventType,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String title;
  final String description;
  final String eventType;
  final bool done;
  final DateTime createdAt;
}
