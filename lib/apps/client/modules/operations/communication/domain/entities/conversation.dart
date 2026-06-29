class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.time,
    this.type = 'text',
    this.attachmentName,
    this.attachmentSize,
    this.duration,
    this.isRead = true,
  });

  final String id;
  final String sender;
  final String senderName;
  final String text;
  final String time;
  final String type;
  final String? attachmentName;
  final String? attachmentSize;
  final String? duration;
  final bool isRead;
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    required this.category,
    required this.lastMessage,
    required this.time,
    required this.initials,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.messages,
    this.meta,
  });

  final String id;
  final String name;
  final String category;
  final String lastMessage;
  final String time;
  final String initials;
  final bool isOnline;
  int unreadCount;
  final List<ChatMessage> messages;
  final Map<String, String>? meta;
}
