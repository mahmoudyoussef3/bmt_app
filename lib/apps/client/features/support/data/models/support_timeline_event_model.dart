import '../../domain/entities/support_timeline_event.dart';

class SupportTimelineEventModel extends SupportTimelineEvent {
  const SupportTimelineEventModel({
    required super.id,
    required super.ticketId,
    required super.title,
    required super.description,
    required super.eventType,
    required super.done,
    required super.createdAt,
  });

  factory SupportTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return SupportTimelineEventModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventType: json['event_type'] as String,
      done: json['done'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
