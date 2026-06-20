import '../entities/conversation.dart';

abstract class CommunicationRepository {
  Future<List<Conversation>> getConversations();

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  });
}
