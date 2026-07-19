/// Who authored a message in a support conversation.
///
/// The backend stores this as free text (`client`, `user`, `support`,
/// `agent`, …); the data layer collapses it to these two roles so the UI never
/// has to compare raw strings.
enum ChatMessageSender { client, agent }

/// The payload a message carries. Unrecognised backend values map to [text] so
/// an unexpected type still renders as a readable bubble.
enum ChatMessageType { text, image, voice }

/// Delivery state of a message. Anything read back from the backend is [sent];
/// [sending] and [failed] only ever describe a message this device just wrote,
/// so a send that fails is visibly distinct from one that landed.
enum ChatMessageStatus { sending, sent, failed }

/// A single message inside a conversation.
///
/// Immutable by construction: appending a message rebuilds the thread rather
/// than mutating it, so `BlocBuilder` always sees a genuinely new object.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.senderName,
    this.sentAt,
    this.type = ChatMessageType.text,
    this.attachmentName,
    this.attachmentSize,
    this.duration,
    this.isRead = true,
    this.status = ChatMessageStatus.sent,
  });

  final String id;
  final ChatMessageSender sender;
  final String text;

  /// Display name of the author. Null for messages the client just sent (the
  /// UI labels those "You") and for backend rows that carried no name.
  final String? senderName;

  /// When the message was authored, in local time. Null when the backend row
  /// carried no parseable timestamp. Formatting belongs to presentation — the
  /// domain never holds a pre-rendered clock string.
  final DateTime? sentAt;

  final ChatMessageType type;
  final String? attachmentName;
  final String? attachmentSize;
  final String? duration;
  final bool isRead;
  final ChatMessageStatus status;

  bool get isFromClient => sender == ChatMessageSender.client;

  ChatMessage copyWith({ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      senderName: senderName,
      sentAt: sentAt,
      type: type,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      duration: duration,
      isRead: isRead,
      status: status ?? this.status,
    );
  }
}
