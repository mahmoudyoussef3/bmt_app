/// Wire shape of one entry in the `operation_complaints.conversation` JSONB
/// array.
///
/// Every field is defensive: the array is unschema'd JSON written by more than
/// one producer, so key names vary and a single malformed entry must not take
/// the whole thread down.
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.text,
    this.sender,
    this.senderName,
    this.createdAt,
    this.type,
    this.attachmentName,
    this.attachmentSize,
    this.duration,
    this.isRead = true,
  });

  final String id;
  final String text;
  final String? sender;
  final String? senderName;
  final String? createdAt;
  final String? type;
  final String? attachmentName;
  final String? attachmentSize;
  final String? duration;
  final bool isRead;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      text:
          json['message']?.toString() ??
          json['text']?.toString() ??
          json['body']?.toString() ??
          '',
      sender:
          json['sender']?.toString() ??
          json['author_role']?.toString() ??
          json['role']?.toString(),
      senderName:
          json['sender_name']?.toString() ?? json['author_name']?.toString(),
      createdAt: (json['created_at'] ?? json['timestamp'])?.toString(),
      type: json['type']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size']?.toString(),
      duration: json['duration']?.toString(),
      isRead: json['is_read'] != false,
    );
  }
}

/// Wire shape of a row in the `operation_complaints` table.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.description,
    required this.messages,
    this.assignedTo,
    this.category,
    this.updatedAt,
    this.status,
    this.priority,
  });

  final String id;
  final String description;
  final List<ChatMessageModel> messages;
  final String? assignedTo;
  final String? category;
  final String? updatedAt;
  final String? status;
  final String? priority;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      messages: conversation is! List
          ? const []
          : conversation
                .whereType<Map>()
                .map(
                  (item) => ChatMessageModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
      assignedTo: json['assigned_to']?.toString(),
      category: json['category']?.toString(),
      updatedAt: (json['updated_at'] ?? json['created_at'])?.toString(),
      status: json['status']?.toString(),
      priority: json['priority']?.toString(),
    );
  }
}
