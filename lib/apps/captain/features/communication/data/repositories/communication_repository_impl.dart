import '../../domain/entities/conversation.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/chat_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  const CommunicationRepositoryImpl(this._dataSource);

  final ChatDatasource _dataSource;

  @override
  Future<CaptainConversation> getConversation({
    required String tripId,
    String? passengerId,
  }) async {
    return (await _dataSource.getConversation(
      tripId: tripId,
      passengerId: passengerId,
    )).toEntity();
  }

  @override
  Future<CaptainConversation> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  }) async {
    return (await _dataSource.sendMessage(
      tripId: tripId,
      passengerId: passengerId,
      text: text,
      type: type,
    )).toEntity();
  }

  @override
  Stream<OpsBroadcast> watchIncomingOpsMessages() =>
      _dataSource.watchIncomingOpsMessages();
}
