import '../../domain/entities/conversation.dart';

/// The conversation-list filter chips. Values are matched against
/// [ConversationCategory]; [all] matches every thread.
enum ConversationFilter {
  all,
  drivers,
  support,
  groups;

  bool matches(Conversation conversation) {
    return switch (this) {
      ConversationFilter.all => true,
      ConversationFilter.drivers =>
        conversation.category == ConversationCategory.driver,
      ConversationFilter.support =>
        conversation.category == ConversationCategory.support,
      ConversationFilter.groups =>
        conversation.category == ConversationCategory.group,
    };
  }
}
