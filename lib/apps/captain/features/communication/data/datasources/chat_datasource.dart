import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';

class ChatDataSource {
  const ChatDataSource();

  Future<CaptainConversationModel> getConversation({
    required String tripId,
    String? passengerId,
  }) async {
    final broadcast = passengerId == null;
    return CaptainConversationModel(
      id: broadcast ? 'broadcast-$tripId' : 'chat-$tripId-$passengerId',
      title: broadcast ? 'All passengers' : 'Passenger $passengerId',
      passengerId: passengerId,
      broadcast: broadcast,
      messages: [
        CaptainMessageModel(
          id: 'm1',
          senderName: 'Captain',
          text: broadcast
              ? 'Please be ready at your pickup point.'
              : 'I am heading to your pickup point.',
          type: CaptainMessageType.text,
        ),
      ],
    );
  }

  Future<CaptainConversationModel> sendMessage({
    required String tripId,
    String? passengerId,
    required String text,
    required CaptainMessageType type,
  }) async {
    final conversation = await getConversation(
      tripId: tripId,
      passengerId: passengerId,
    );
    return CaptainConversationModel(
      id: conversation.id,
      title: conversation.title,
      passengerId: conversation.passengerId,
      broadcast: conversation.broadcast,
      messages: [
        ...conversation.messages,
        CaptainMessageModel(
          id: 'm${conversation.messages.length + 1}',
          senderName: 'Captain',
          text: text,
          type: type,
        ),
      ],
    );
  }
}
