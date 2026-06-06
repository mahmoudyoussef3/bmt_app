import '../../domain/entities/conversation.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/mock_communication_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl(this._datasource);

  final MockCommunicationDatasource _datasource;

  @override
  Future<List<Conversation>> getConversations() async {
    final conversations = await _datasource.getConversations();
    return conversations
        .map((conversation) => conversation.toEntity())
        .toList();
  }
}
