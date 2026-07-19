import '../../domain/entities/conversation.dart';

sealed class ChatThreadState {
  const ChatThreadState();
}

class ChatThreadLoading extends ChatThreadState {
  const ChatThreadLoading();
}

class ChatThreadLoaded extends ChatThreadState {
  const ChatThreadLoaded(this.conversation, {this.sendError});

  final Conversation conversation;

  /// Set when the most recent send failed, and cleared once the UI has
  /// reported it, so the same failure is never announced twice.
  final String? sendError;

  ChatThreadLoaded copyWith({
    Conversation? conversation,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatThreadLoaded(
      conversation ?? this.conversation,
      sendError: clearSendError ? null : sendError ?? this.sendError,
    );
  }
}

class ChatThreadError extends ChatThreadState {
  const ChatThreadError(this.message);

  final String message;
}
