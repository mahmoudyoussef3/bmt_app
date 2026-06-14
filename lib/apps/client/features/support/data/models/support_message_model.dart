import '../../domain/entities/support_message.dart';
import 'support_attachment_model.dart';

class SupportMessageModel extends SupportMessage {
  const SupportMessageModel({
    required super.id,
    required super.ticketId,
    required super.senderType,
    super.senderId,
    required super.senderName,
    required super.message,
    required super.createdAt,
    super.attachments = const [],
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderType: _parseSenderType(json['sender_type'] as String?),
      senderId: json['sender_id'] as String?,
      senderName: json['sender_name'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => SupportAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static MessageSenderType _parseSenderType(String? type) {
    switch (type?.toLowerCase()) {
      case 'client':
        return MessageSenderType.client;
      case 'agent':
        return MessageSenderType.agent;
      case 'system':
      default:
        return MessageSenderType.system;
    }
  }
}
