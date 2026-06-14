import '../repositories/support_repository.dart';
import '../entities/support_message.dart';

class SendTicketMessageUseCase {
  final SupportRepository _repository;

  const SendTicketMessageUseCase(this._repository);

  Future<SupportMessage> call({
    required String ticketId,
    required String message,
  }) {
    return _repository.sendTicketMessage(
      ticketId: ticketId,
      message: message,
    );
  }
}
