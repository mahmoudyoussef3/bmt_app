/// Arguments for `CommunicationRoutes.chatThread`.
///
/// The thread loads itself from the backend, so the list only forwards which
/// conversation to open — never the conversation object, which would go stale
/// the moment an agent replied.
class ChatThreadArguments {
  const ChatThreadArguments({required this.conversationId});

  factory ChatThreadArguments.fromArguments(Object? arguments) {
    return ChatThreadArguments(
      conversationId: arguments is Map
          ? arguments['conversationId']?.toString() ?? ''
          : '',
    );
  }

  final String conversationId;

  Map<String, Object?> toArguments() => {'conversationId': conversationId};

  bool get isValid => conversationId.isNotEmpty;
}
