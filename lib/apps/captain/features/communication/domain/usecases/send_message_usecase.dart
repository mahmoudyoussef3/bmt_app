import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<CaptainConversation> call({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  }) {
    return _repository.sendMessage(
      tripId: tripId,
      passengerId: passengerId,
      text: text,
      type: type,
    );
  }
}
