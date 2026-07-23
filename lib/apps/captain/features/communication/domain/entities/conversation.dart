enum CaptainMessageType { text, image, voice }

class CaptainMessage {
  const CaptainMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.type,
    required this.isMine,
  });

  final String id;
  final String senderName;
  final String text;
  final CaptainMessageType type;

  /// Whether the captain wrote this message.
  ///
  /// Carried explicitly because the bubble's side and colour depend on it, and
  /// the display name cannot answer it: the datasource labels rows `أنت` or
  /// `العمليات`, so the screen's old `senderName.contains('Captain')` test
  /// matched neither and drew every message — including the captain's own — as
  /// an incoming one.
  final bool isMine;
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
