import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class AddSupportMessageUseCase {
  const AddSupportMessageUseCase(this._repository);

  final SupportRepository _repository;

  Future<SupportTicket> call({
    required SupportTicket ticket,
    required String sender,
    required String text,
    required String time,
  }) async {
    return _repository.addMessage(ticket.id, {
      'sender': sender,
      'text': text,
      'time': time,
    });
  }
}
