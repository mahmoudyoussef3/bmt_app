import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class RespondToComplaintUseCase {
  final TicketsRepository _repository;

  const RespondToComplaintUseCase(this._repository);

  Future<Complaint> call(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  }) {
    return _repository.respondToComplaint(
      id,
      senderName: senderName,
      senderType: senderType,
      content: content,
      attachments: attachments,
    );
  }
}
