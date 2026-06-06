import '../../domain/entities/conversation.dart';

sealed class CommunicationState {
  const CommunicationState();
}

class CommunicationLoading extends CommunicationState {
  const CommunicationLoading();
}

class CommunicationLoaded extends CommunicationState {
  const CommunicationLoaded({
    required this.conversations,
    this.activeConversationId,
  });

  final List<Conversation> conversations;
  final String? activeConversationId;

  Conversation? get activeConversation {
    if (activeConversationId == null) return null;
    return conversations.cast<Conversation?>().firstWhere(
      (conversation) => conversation?.id == activeConversationId,
      orElse: () => null,
    );
  }

  CommunicationLoaded copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
  }) {
    return CommunicationLoaded(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
    );
  }
}

class CommunicationError extends CommunicationState {
  const CommunicationError(this.message);

  final String message;
}
