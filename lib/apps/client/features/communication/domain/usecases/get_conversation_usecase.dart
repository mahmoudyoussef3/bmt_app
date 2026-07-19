import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetConversationUseCase {
  const GetConversationUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Conversation> call(String conversationId) {
    return _repository.getConversation(conversationId);
  }
}
