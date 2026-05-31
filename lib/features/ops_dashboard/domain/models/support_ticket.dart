enum TicketStatus { open, inProgress, resolved, escalated, closed }

enum TicketPriority { low, medium, high, critical }

class InternalNote {
  final String agentId;
  final String note;
  final DateTime createdAt;

  InternalNote({required this.agentId, required this.note, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();
}

class SupportTicket {
  final String id;
  final String customerId;
  final String subject;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachments;
  final String? assignedAgentId;
  final List<InternalNote> internalNotes;

  SupportTicket({
    required this.id,
    required this.customerId,
    required this.subject,
    required this.description,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    DateTime? createdAt,
    this.updatedAt,
    this.attachments = const [],
    this.assignedAgentId,
    this.internalNotes = const [],
  }) : createdAt = createdAt ?? DateTime.now();
}
