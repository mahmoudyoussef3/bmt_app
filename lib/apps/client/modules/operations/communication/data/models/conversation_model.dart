import '../../domain/entities/conversation.dart';

class ChatMessageModel {
  const ChatMessageModel({
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

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sender: sender,
      senderName: senderName,
      text: text,
      time: time,
      type: type,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      duration: duration,
      isRead: isRead,
    );
  }
}

class ConversationModel {
  const ConversationModel({
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
  final int unreadCount;
  final List<ChatMessageModel> messages;
  final Map<String, String>? meta;

  Conversation toEntity() {
    return Conversation(
      id: id,
      name: name,
      category: category,
      lastMessage: lastMessage,
      time: time,
      initials: initials,
      isOnline: isOnline,
      unreadCount: unreadCount,
      messages: messages.map((message) => message.toEntity()).toList(),
      meta: meta,
    );
  }
}
