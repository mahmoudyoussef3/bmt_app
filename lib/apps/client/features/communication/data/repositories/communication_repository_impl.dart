import '../../domain/entities/conversation.dart';
import '../../domain/repositories/communication_repository.dart';

import '../datasources/supabase_communication_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl(this._datasource);

  final SupabaseCommunicationDatasource _datasource;

  @override
  Future<List<Conversation>> getConversations() async {
    final conversations = await _datasource.getConversations();
    return conversations
        .map((conversation) => conversation.toEntity())
        .toList();
  }
}
