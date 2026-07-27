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

/// One operations broadcast, carrying the row's identity alongside its text.
///
/// The identity is the point. The banner used to be fed a bare `String` and
/// suppressed anything equal to the last one it showed — so operations sending
/// the same instruction twice ("توقف عند المحطة القادمة", once now and once ten
/// minutes later) produced exactly one banner, and the captain never learned
/// about the second. Repetition is not duplication: an operator repeating
/// themselves usually means the first one was not acted on.
class OpsBroadcast {
  const OpsBroadcast({required this.id, required this.body});

  final String id;
  final String body;
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
