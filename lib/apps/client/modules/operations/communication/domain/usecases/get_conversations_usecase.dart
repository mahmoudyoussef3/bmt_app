import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetConversationsUseCase {
  const GetConversationsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<List<Conversation>> call() {
    return _repository.getConversations();
  }
}
