import 'dart:io';
import '../repositories/support_repository.dart';
import '../entities/support_attachment.dart';

class UploadSupportAttachmentUseCase {
  final SupportRepository _repository;

  const UploadSupportAttachmentUseCase(this._repository);

  Future<SupportAttachment> call({
    required String ticketId,
    String? messageId,
    required File file,
  }) {
    return _repository.uploadAttachment(
      ticketId: ticketId,
      messageId: messageId,
      file: file,
    );
  }
}
