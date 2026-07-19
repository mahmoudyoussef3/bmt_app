import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/send_conversation_message_usecase.dart';
import 'chat_thread_state.dart';

/// Owns one open conversation: reading it fresh and sending into it.
class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit({
    required GetConversationUseCase getConversation,
    required SendConversationMessageUseCase sendMessage,
  }) : _getConversation = getConversation,
       _sendMessage = sendMessage,
       super(const ChatThreadLoading());

  final GetConversationUseCase _getConversation;
  final SendConversationMessageUseCase _sendMessage;

  Future<void> load(String conversationId) async {
    emit(const ChatThreadLoading());
    try {
      final conversation = await _getConversation(conversationId);
      if (isClosed) return;
      emit(ChatThreadLoaded(conversation));
    } catch (error) {
      if (isClosed) return;
      emit(ChatThreadError(error.toString()));
    }
  }

  /// Shows the message immediately as [ChatMessageStatus.sending], then marks
  /// it sent or failed once the write resolves — a failed send stays visible
  /// and visibly undelivered rather than passing for a delivered one.
  Future<void> send(String text) async {
    final current = state;
    if (current is! ChatThreadLoaded) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final pending = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: ChatMessageSender.client,
      text: trimmed,
      sentAt: DateTime.now(),
      status: ChatMessageStatus.sending,
    );

    emit(
      current.copyWith(
        conversation: current.conversation.copyWith(
          messages: [...current.conversation.messages, pending],
          updatedAt: pending.sentAt,
        ),
        clearSendError: true,
      ),
    );

    try {
      await _sendMessage(
        conversationId: current.conversation.id,
        text: trimmed,
      );
      _settle(pending.id, ChatMessageStatus.sent);
    } catch (error) {
      _settle(pending.id, ChatMessageStatus.failed, error: error.toString());
    }
  }

  /// Called once the UI has surfaced [ChatThreadLoaded.sendError].
  void acknowledgeSendError() {
    final current = state;
    if (current is! ChatThreadLoaded) return;
    emit(current.copyWith(clearSendError: true));
  }

  void _settle(String messageId, ChatMessageStatus status, {String? error}) {
    if (isClosed) return;

    final current = state;
    if (current is! ChatThreadLoaded) return;

    final messages = [
      for (final message in current.conversation.messages)
        if (message.id == messageId)
          message.copyWith(status: status)
        else
          message,
    ];

    emit(
      ChatThreadLoaded(
        current.conversation.copyWith(messages: messages),
        sendError: error,
      ),
    );
  }
}
