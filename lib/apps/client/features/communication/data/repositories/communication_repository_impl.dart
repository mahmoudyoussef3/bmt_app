import '../../domain/entities/conversation.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_datasource.dart';
import '../mappers/conversation_mapper.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl(this._datasource);

  final CommunicationDatasource _datasource;

  @override
  Future<List<Conversation>> getConversations() async {
    final conversations = await _datasource.getConversations();
    return conversations.toEntities();
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    final conversation = await _datasource.getConversation(conversationId);
    return conversation.toEntity();
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) {
    return _datasource.appendClientMessage(
      conversationId: conversationId,
      text: text,
    );
  }
}
