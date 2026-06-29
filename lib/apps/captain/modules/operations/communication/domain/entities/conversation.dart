enum CaptainMessageType { text, image, voice }

class CaptainMessage {
  const CaptainMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.type,
  });

  final String id;
  final String senderName;
  final String text;
  final CaptainMessageType type;
}

class CaptainConversation {
  const CaptainConversation({
    required this.id,
    required this.title,
    required this.messages,
    this.passengerId,
    this.broadcast = false,
  });

  final String id;
  final String title;
  final List<CaptainMessage> messages;
  final String? passengerId;
  final bool broadcast;
}
