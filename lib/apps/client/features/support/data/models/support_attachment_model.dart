import '../../domain/entities/support_attachment.dart';

class SupportAttachmentModel extends SupportAttachment {
  const SupportAttachmentModel({
    required super.id,
    required super.ticketId,
    super.messageId,
    required super.fileUrl,
    required super.fileName,
    required super.fileType,
    super.fileSize,
    required super.createdAt,
  });

  factory SupportAttachmentModel.fromJson(Map<String, dynamic> json) {
    return SupportAttachmentModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      messageId: json['message_id'] as String?,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
