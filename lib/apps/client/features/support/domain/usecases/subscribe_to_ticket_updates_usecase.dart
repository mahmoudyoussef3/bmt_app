import '../repositories/support_repository.dart';
import '../entities/support_message.dart';
import '../entities/support_ticket.dart';

class SubscribeToTicketUpdatesUseCase {
  final SupportRepository _repository;

  const SubscribeToTicketUpdatesUseCase(this._repository);

  Stream<List<SupportMessage>> messages(String ticketId) {
    return _repository.subscribeToMessages(ticketId);
  }

  Stream<SupportTicket> ticketUpdates(String ticketId) {
    return _repository.subscribeToTicketUpdates(ticketId);
  }
}
