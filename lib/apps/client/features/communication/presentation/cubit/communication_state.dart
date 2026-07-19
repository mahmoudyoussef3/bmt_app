import '../../domain/entities/conversation.dart';
import '../models/conversation_filter.dart';

sealed class CommunicationState {
  const CommunicationState();
}

class CommunicationLoading extends CommunicationState {
  const CommunicationLoading();
}

class CommunicationLoaded extends CommunicationState {
  const CommunicationLoaded({
    required this.conversations,
    this.query = '',
    this.filter = ConversationFilter.all,
  });

  final List<Conversation> conversations;

  /// Live search text and filter chip. They live here rather than in the
  /// widget so the list is a pure function of cubit state.
  final String query;
  final ConversationFilter filter;

  /// Threads matching the current search text and filter chip.
  List<Conversation> get visibleConversations {
    final needle = query.trim().toLowerCase();
    return conversations.where((conversation) {
      if (!filter.matches(conversation)) return false;
      if (needle.isEmpty) return true;
      return conversation.name.toLowerCase().contains(needle) ||
          conversation.lastMessage.toLowerCase().contains(needle);
    }).toList();
  }

  CommunicationLoaded copyWith({
    List<Conversation>? conversations,
    String? query,
    ConversationFilter? filter,
  }) {
    return CommunicationLoaded(
      conversations: conversations ?? this.conversations,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class CommunicationError extends CommunicationState {
  const CommunicationError(this.message);

  final String message;
}
