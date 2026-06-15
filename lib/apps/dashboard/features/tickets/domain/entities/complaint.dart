enum TicketStatus {
  submitted('Submitted'),
  underReview('Under Review'),
  contacted('Contacted'),
  resolved('Resolved'),
  closed('Closed'),
  rejected('Rejected');

  final String label;
  const TicketStatus(this.label);
}

enum TicketPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String label;
  const TicketPriority(this.label);
}

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String category;
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedAgentName;
  final String? internalNote;
  final DateTime? customerContactedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedAgentName,
    this.internalNote,
    this.customerContactedAt,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
  });

  SupportTicket copyWith({
    String? id,
    String? ticketNumber,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? category,
    String? title,
    String? description,
    TicketPriority? priority,
    TicketStatus? status,
    String? assignedAgentName,
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
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      internalNote: internalNote ?? this.internalNote,
      customerContactedAt: customerContactedAt ?? this.customerContactedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class SupportAttachment {
  final String id;
  final String fileUrl;
  final String fileName;

  const SupportAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });
}
