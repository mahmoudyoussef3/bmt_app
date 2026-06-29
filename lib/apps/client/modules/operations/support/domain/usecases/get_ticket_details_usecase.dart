import '../repositories/support_repository.dart';
import '../entities/support_ticket.dart';

class GetTicketDetailsUseCase {
  final SupportRepository _repository;

  const GetTicketDetailsUseCase(this._repository);

  Future<SupportTicket> call(String ticketId) {
    return _repository.getTicketDetails(ticketId);
  }
}
