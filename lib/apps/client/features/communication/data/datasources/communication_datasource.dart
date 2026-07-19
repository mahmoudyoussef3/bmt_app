import '../models/conversation_model.dart';

abstract class CommunicationDatasource {
  /// The signed-in client's support threads, newest activity first.
  Future<List<ConversationModel>> getConversations();

  /// A single thread belonging to the signed-in client.
  Future<ConversationModel> getConversation(String conversationId);

  /// Appends a client-authored text message to a thread.
  Future<void> appendClientMessage({
    required String conversationId,
    required String text,
  });
}
