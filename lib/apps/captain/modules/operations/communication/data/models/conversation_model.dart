import '../../domain/entities/conversation.dart';

class CaptainMessageModel {
  const CaptainMessageModel({
    required this.id,
    required this.senderName,
    required this.text,
    required this.type,
  });

  final String id;
  final String senderName;
  final String text;
  final CaptainMessageType type;

  CaptainMessage toEntity() {
    return CaptainMessage(
      id: id,
      senderName: senderName,
      text: text,
      type: type,
    );
  }
}

class CaptainConversationModel {
  const CaptainConversationModel({
    required this.id,
    required this.title,
    required this.messages,
    this.passengerId,
    this.broadcast = false,
  });

  final String id;
  final String title;
  final List<CaptainMessageModel> messages;
  final String? passengerId;
  final bool broadcast;

  CaptainConversation toEntity() {
    return CaptainConversation(
      id: id,
      title: title,
      messages: messages.map((message) => message.toEntity()).toList(),
      passengerId: passengerId,
      broadcast: broadcast,
    );
  }
}
