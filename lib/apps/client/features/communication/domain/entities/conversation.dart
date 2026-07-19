import 'chat_message.dart';

/// The kind of counterpart the client is talking to.
///
/// Backed by `operation_complaints.category`, which is unconstrained free
/// text, so anything unrecognised becomes [other].
enum ConversationCategory { driver, support, group, other }

/// One support conversation: a complaint row plus the message thread stored in
/// its `conversation` JSONB column.
///
/// Immutable. Preview text and avatar initials are derived rather than stored,
/// so they can never drift out of sync with [messages] and [name].
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryName,
    required this.description,
    required this.messages,
    this.updatedAt,
    this.status,
    this.priority,
  });

  final String id;

  /// The assigned agent, or a support-team fallback when the complaint is
  /// still unassigned.
  final String name;

  final ConversationCategory category;

  /// The backend's raw `category` text. The column is unconstrained, so values
  /// outside [ConversationCategory] are shown verbatim rather than discarded.
  final String categoryName;

  /// The complaint body. Doubles as the conversation-list preview while the
  /// thread is still empty.
  final String description;

  final List<ChatMessage> messages;
  final DateTime? updatedAt;

  /// Raw `status` / `priority` values. Left as free text because the column
  /// carries no CHECK constraint — presentation labels the values it knows and
  /// shows the raw string otherwise.
  final String? status;
  final String? priority;

  /// Preview line for the conversation list: the newest message, falling back
  /// to the complaint description for a thread nobody has replied in yet.
  String get lastMessage => messages.isEmpty ? description : messages.last.text;

  /// Up to two uppercase initials derived from [name], for avatar placeholders.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return 'ST';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  /// Only the fields that change while a conversation is on screen: appending
  /// a message and bumping the thread's timestamp.
  Conversation copyWith({List<ChatMessage>? messages, DateTime? updatedAt}) {
    return Conversation(
      id: id,
      name: name,
      category: category,
      categoryName: categoryName,
      description: description,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status,
      priority: priority,
    );
  }
}
