import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';

abstract class ChatDatasource {
  Future<CaptainConversationModel> getConversation({
    required String tripId,
    String? passengerId,
  });

  Future<CaptainConversationModel> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  });

  Stream<OpsBroadcast> watchIncomingOpsMessages();
}
