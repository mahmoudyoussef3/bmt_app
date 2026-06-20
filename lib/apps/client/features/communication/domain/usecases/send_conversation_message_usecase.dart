import '../repositories/communication_repository.dart';

class SendConversationMessageUseCase {
  const SendConversationMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<void> call({required String conversationId, required String text}) {
    return _repository.sendMessage(conversationId: conversationId, text: text);
  }
}
