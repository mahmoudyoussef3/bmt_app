enum TicketStatus {
  submitted,
  underReview,
  contacted,
  resolved,
  closed,
  rejected,
}

enum TicketPriority { low, medium, high, urgent }

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedAgentName,
    this.relatedBookingId,
    this.relatedTripId,
    this.internalNote,
    this.customerContactedAt,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
  });

  final String id;
  final String ticketNumber;
  final String category;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedAgentName;
  final String? relatedBookingId;
  final String? relatedTripId;
  final String? internalNote;
  final DateTime? customerContactedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  SupportTicket copyWith({
    String? id,
    String? ticketNumber,
    String? category,
    String? title,
    String? description,
    TicketPriority? priority,
    TicketStatus? status,
    String? assignedAgentName,
    String? relatedBookingId,
    String? relatedTripId,
    String? internalNote,
    DateTime? customerContactedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      relatedTripId: relatedTripId ?? this.relatedTripId,
      internalNote: internalNote ?? this.internalNote,
      customerContactedAt: customerContactedAt ?? this.customerContactedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
