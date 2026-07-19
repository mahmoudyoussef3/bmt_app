import '../entities/conversation.dart';

abstract class CommunicationRepository {
  Future<List<Conversation>> getConversations();

  /// One thread, read fresh — an agent may have replied since the list loaded.
  Future<Conversation> getConversation(String conversationId);

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  });
}
