import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class CloseTicketUseCase {
  final TicketsRepository _repository;

  const CloseTicketUseCase(this._repository);

  Future<SupportTicket> call(String id) {
    return _repository.closeTicket(id);
  }
}
