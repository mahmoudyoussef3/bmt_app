import '../../domain/entities/support_ticket.dart';

class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.ticketNumber,
    required super.category,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    super.assignedAgentName,
    super.relatedBookingId,
    super.relatedTripId,
    required super.createdAt,
    required super.updatedAt,
    super.resolvedAt,
    super.closedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: _parsePriority(json['priority'] as String?),
      status: _parseStatus(json['status'] as String?),
      assignedAgentName: json['assigned_agent_name'] as String?,
      relatedBookingId: json['related_booking_id'] as String?,
      relatedTripId: json['related_trip_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
    );
  }

  static TicketStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return TicketStatus.open;
      case 'underreview':
      case 'under_review':
        return TicketStatus.underReview;
      case 'inprogress':
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  static TicketPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return TicketPriority.urgent;
      case 'high':
        return TicketPriority.high;
      case 'medium':
        return TicketPriority.medium;
      case 'low':
      default:
        return TicketPriority.low;
    }
  }
}
