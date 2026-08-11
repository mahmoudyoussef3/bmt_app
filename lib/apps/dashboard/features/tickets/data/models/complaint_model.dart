import '../../domain/entities/complaint.dart';

class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.ticketNumber,
    required super.clientId,
    required super.clientName,
    required super.clientPhone,
    required super.category,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    super.assignedAgentName,
    super.assignedAgentId,
    super.internalNote,
    super.customerContactedAt,
    required super.createdAt,
    required super.updatedAt,
    super.resolvedAt,
    super.closedAt,
    super.slaDueAt,
    super.slaBreached,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    
    String clientName = 'Unknown User';
    String clientPhone = '';

    if (json['clients'] != null) {
      clientName = json['clients']['full_name'] as String? ?? 'Unknown User';
      clientPhone = json['clients']['phone'] as String? ?? '';
    }

    return SupportTicketModel(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String,
      clientId: json['client_id'] as String,
      clientName: clientName,
      clientPhone: clientPhone,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: _parsePriority(json['priority'] as String?),
      status: _parseStatus(json['status'] as String?),
      assignedAgentName: json['assigned_agent_name'] as String?,
      assignedAgentId: json['assigned_agent_id'] as String?,
      internalNote: json['internal_note'] as String?,
      customerContactedAt: json['customer_contacted_at'] != null
          ? DateTime.parse(json['customer_contacted_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String).toLocal()
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String).toLocal()
          : null,
      slaDueAt: json['sla_due_at'] != null
          ? DateTime.parse(json['sla_due_at'] as String).toLocal()
          : null,
      slaBreached: json['sla_breached'] as bool? ?? false,
    );
  }

  static TicketStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return TicketStatus.submitted;
      case 'underreview':
      case 'under_review':
        return TicketStatus.underReview;
      case 'contacted':
        return TicketStatus.contacted;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      case 'rejected':
        return TicketStatus.rejected;
      default:
        return TicketStatus.submitted;
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

class SupportAttachmentModel extends SupportAttachment {
  const SupportAttachmentModel({
    required super.id,
    required super.fileUrl,
    required super.fileName,
  });

  factory SupportAttachmentModel.fromJson(Map<String, dynamic> json) {
    return SupportAttachmentModel(
      id: json['id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
    );
  }
}
