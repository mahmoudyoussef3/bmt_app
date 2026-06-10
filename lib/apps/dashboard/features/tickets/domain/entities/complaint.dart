enum ComplaintStatus {
  newlyCreated('جديدة'),
  inProgress('قيد المعالجة'),
  waitingForClient('بانتظار العميل'),
  resolved('تم الحل'),
  closed('مغلقة');

  final String label;
  const ComplaintStatus(this.label);
}

enum ComplaintPriority {
  low('منخفضة'),
  medium('متوسطة'),
  high('مرتفعة'),
  critical('حرجة');

  final String label;
  const ComplaintPriority(this.label);
}

enum ComplaintCategory {
  tripDelay('تأخير الرحلة'),
  driverBehavior('سلوك السائق'),
  vehicleCleanliness('نظافة المركبة'),
  appIssue('مشكلة في التطبيق'),
  lostItem('مفقودات'),
  paymentIssue('مشاكل الدفع'),
  other('أخرى');

  final String label;
  const ComplaintCategory(this.label);
}

class ComplaintMessage {
  final String id;
  final String senderName;
  final String senderType; // 'client', 'agent', 'system'
  final String content;
  final DateTime timestamp;
  final List<String> attachments;

  const ComplaintMessage({
    required this.id,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    required this.attachments,
  });

  ComplaintMessage copyWith({
    String? id,
    String? senderName,
    String? senderType,
    String? content,
    DateTime? timestamp,
    List<String>? attachments,
  }) {
    return ComplaintMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
    );
  }
}

class ComplaintLog {
  final String id;
  final String action;
  final DateTime timestamp;
  final String actor;

  const ComplaintLog({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.actor,
  });
}

class Complaint {
  final String id;
  final String clientName;
  final String clientPhone;
  final ComplaintCategory category;
  final String tripCode;
  final DateTime createdAt;
  final String? assignedTo;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String description;
  final List<ComplaintMessage> conversation;
  final List<String> attachments;
  final List<ComplaintLog> history;

  const Complaint({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.category,
    required this.tripCode,
    required this.createdAt,
    this.assignedTo,
    required this.status,
    required this.priority,
    required this.description,
    required this.conversation,
    required this.attachments,
    required this.history,
  });

  Complaint copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    ComplaintCategory? category,
    String? tripCode,
    DateTime? createdAt,
    String? assignedTo,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    String? description,
    List<ComplaintMessage>? conversation,
    List<String>? attachments,
    List<ComplaintLog>? history,
  }) {
    return Complaint(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      category: category ?? this.category,
      tripCode: tripCode ?? this.tripCode,
      createdAt: createdAt ?? this.createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      conversation: conversation ?? this.conversation,
      attachments: attachments ?? this.attachments,
      history: history ?? this.history,
    );
  }
}
