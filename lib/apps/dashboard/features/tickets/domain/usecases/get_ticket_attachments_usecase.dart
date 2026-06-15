import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class GetTicketAttachmentsUseCase {
  final TicketsRepository _repository;

  const GetTicketAttachmentsUseCase(this._repository);

  Future<List<SupportAttachment>> call(String ticketId) {
    return _repository.getTicketAttachments(ticketId);
  }
}
