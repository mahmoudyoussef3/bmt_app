import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/usecases/add_conversation_message_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/send_conversation_message_usecase.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit({
    required GetConversationsUseCase getConversations,
    required AddConversationMessageUseCase addMessage,
    required SendConversationMessageUseCase sendMessage,
  }) : _getConversations = getConversations,
       _addMessage = addMessage,
       _sendMessage = sendMessage,
       super(const CommunicationLoading());

  final GetConversationsUseCase _getConversations;
  final AddConversationMessageUseCase _addMessage;
  final SendConversationMessageUseCase _sendMessage;

  Future<void> load() async {
    emit(const CommunicationLoading());
    try {
      final conversations = await _getConversations();
      emit(CommunicationLoaded(conversations: conversations));
    } catch (error) {
      emit(CommunicationError(error.toString()));
    }
  }

  void selectConversation(Conversation conversation) {
    final current = state;
    if (current is! CommunicationLoaded) return;
    conversation.unreadCount = 0;
    emit(current.copyWith(activeConversationId: conversation.id));
  }

  Future<void> addMessage(ChatMessage message, {String? conversationId}) async {
    final current = state;
    if (current is! CommunicationLoaded) return;
    final id = conversationId ?? current.activeConversationId;
    if (id == null) return;
    final conversation = current.conversations.cast<Conversation?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
    if (conversation == null) return;

    // Optimistically render the message, then persist it to the backend.
    _addMessage(conversation: conversation, message: message);
    emit(current.copyWith(conversations: List.of(current.conversations)));

    final isClientMessage =
        message.sender == 'client' || message.sender == 'user';
    if (isClientMessage && message.type == 'text' && message.text.isNotEmpty) {
      try {
        await _sendMessage(conversationId: id, text: message.text);
      } catch (_) {
        // Keep the optimistic message; a reload will reconcile with the server.
      }
    }
  }

  void incrementUnread(String initials) {
    final current = state;
    if (current is! CommunicationLoaded) return;
    final conversation = current.conversations.cast<Conversation?>().firstWhere(
      (item) => item?.initials == initials,
      orElse: () => null,
    );
    if (conversation == null) return;
    conversation.unreadCount++;
    emit(current.copyWith(conversations: List.of(current.conversations)));
  }
}
