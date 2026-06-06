import '../entities/conversation.dart';

class AddConversationMessageUseCase {
  const AddConversationMessageUseCase();

  void call({
    required Conversation conversation,
    required ChatMessage message,
  }) {
    conversation.messages.add(message);
  }
}
