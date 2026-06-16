import '../entities/conversation.dart';

abstract class CommunicationRepository {
  Future<CaptainConversation> getConversation({
    required String tripId,
    String? passengerId,
  });

  Future<CaptainConversation> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  });

  Stream<String> watchIncomingOpsMessages();
}
