import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/usecases/add_conversation_message_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  CommunicationCubit({
    required GetConversationsUseCase getConversations,
    required AddConversationMessageUseCase addMessage,
  }) : _getConversations = getConversations,
       _addMessage = addMessage,
       super(const CommunicationLoading());

  final GetConversationsUseCase _getConversations;
  final AddConversationMessageUseCase _addMessage;

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

  void addMessage(ChatMessage message, {String? conversationId}) {
    final current = state;
    if (current is! CommunicationLoaded) return;
    final id = conversationId ?? current.activeConversationId;
    if (id == null) return;
    final conversation = current.conversations.cast<Conversation?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
    if (conversation == null) return;
    _addMessage(conversation: conversation, message: message);
    emit(current.copyWith(conversations: List.of(current.conversations)));
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
