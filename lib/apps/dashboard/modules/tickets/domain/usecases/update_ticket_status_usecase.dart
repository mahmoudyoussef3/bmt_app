import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class UpdateTicketStatusUseCase {
  final TicketsRepository _repository;

  const UpdateTicketStatusUseCase(this._repository);

  Future<SupportTicket> call(String id, TicketStatus status) {
    return _repository.updateTicketStatus(id, status);
  }
}
