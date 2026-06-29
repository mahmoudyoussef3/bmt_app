import '../repositories/support_repository.dart';
import '../entities/support_ticket.dart';

class GetMySupportTicketsUseCase {
  final SupportRepository _repository;

  const GetMySupportTicketsUseCase(this._repository);

  Future<List<SupportTicket>> call() {
    return _repository.getMyTickets();
  }
}
