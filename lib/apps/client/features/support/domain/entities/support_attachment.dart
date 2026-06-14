class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.ticketId,
    this.messageId,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    this.fileSize,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String? messageId;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int? fileSize;
  final DateTime createdAt;
}
