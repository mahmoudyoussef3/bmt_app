import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';

/// Fallback display name for a complaint nobody has been assigned to yet.
const _unassignedAgentName = 'Support Team';

extension ConversationMapper on ConversationModel {
  Conversation toEntity() {
    final agent = assignedTo?.trim();

    return Conversation(
      id: id,
      name: agent == null || agent.isEmpty ? _unassignedAgentName : agent,
      category: _category(category),
      categoryName: category?.trim() ?? '',
      description: description,
      messages: messages.toEntities(),
      updatedAt: DateTime.tryParse(updatedAt ?? '')?.toLocal(),
      status: status,
      priority: priority,
    );
  }
}

extension ConversationListMapper on List<ConversationModel> {
  List<Conversation> toEntities() => map((model) => model.toEntity()).toList();
}

extension ChatMessageMapper on ChatMessageModel {
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sender: _sender(sender),
      text: text,
      senderName: senderName,
      sentAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
      type: _type(type),
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      duration: duration,
      isRead: isRead,
    );
  }
}

extension ChatMessageListMapper on List<ChatMessageModel> {
  List<ChatMessage> toEntities() => map((model) => model.toEntity()).toList();
}

// Backend-string knowledge lives here in the data layer so the domain enums
// stay pure Dart. All three columns are unconstrained text, so every parser
// falls back rather than throwing on an unexpected value.

ConversationCategory _category(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'driver' => ConversationCategory.driver,
    'support' => ConversationCategory.support,
    'group' => ConversationCategory.group,
    _ => ConversationCategory.other,
  };
}

ChatMessageSender _sender(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'client' || 'user' => ChatMessageSender.client,
    _ => ChatMessageSender.agent,
  };
}

ChatMessageType _type(String? raw) {
  return switch (raw?.trim().toLowerCase()) {
    'image' => ChatMessageType.image,
    'voice' => ChatMessageType.voice,
    _ => ChatMessageType.text,
  };
}
