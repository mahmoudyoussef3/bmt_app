import '../../domain/entities/conversation.dart';

sealed class CaptainCommunicationState {
  const CaptainCommunicationState();
}

class CaptainCommunicationLoading extends CaptainCommunicationState {
  const CaptainCommunicationLoading();
}

class CaptainCommunicationLoaded extends CaptainCommunicationState {
  const CaptainCommunicationLoaded(this.conversation);

  final CaptainConversation conversation;
}

class CaptainCommunicationError extends CaptainCommunicationState {
  const CaptainCommunicationError(this.message);

  final String message;
}
