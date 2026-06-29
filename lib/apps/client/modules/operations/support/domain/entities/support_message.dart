import 'support_attachment.dart';

enum MessageSenderType { client, agent, system }

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final String ticketId;
  final MessageSenderType senderType;
  final String? senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final List<SupportAttachment> attachments;
}
