import '../entities/conversation.dart';

abstract class CommunicationRepository {
  Future<List<Conversation>> getConversations();
}
