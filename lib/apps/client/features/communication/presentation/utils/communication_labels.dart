import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/conversation.dart';
import '../models/conversation_filter.dart';

/// Display label for a conversation's category. Known categories are
/// translated; anything else falls back to the backend's raw value.
String categoryLabel(BuildContext context, Conversation conversation) {
  final l10n = context.l10n;
  return switch (conversation.category) {
    ConversationCategory.driver => l10n.communication_categoryDriver,
    ConversationCategory.support => l10n.communication_categorySupport,
    ConversationCategory.group => l10n.communication_categoryGroup,
    ConversationCategory.other => conversation.categoryName,
  };
}

/// Display label for a filter chip.
String filterLabel(BuildContext context, ConversationFilter filter) {
  final l10n = context.l10n;
  return switch (filter) {
    ConversationFilter.all => l10n.communication_filterAll,
    ConversationFilter.drivers => l10n.communication_filterDrivers,
    ConversationFilter.support => l10n.communication_filterSupport,
    ConversationFilter.groups => l10n.communication_filterGroups,
  };
}

/// Display label for a complaint status. `newlyCreated` is the column default
/// and reads as "Open" to the client.
String statusLabel(BuildContext context, String? status) {
  final raw = status?.trim();
  if (raw == null || raw.isEmpty || raw == 'newlyCreated') {
    return context.l10n.communication_statusOpenFallback;
  }
  return raw;
}

/// Locale-aware relative time for a conversation or message timestamp.
String displayTime(BuildContext context, DateTime? value) {
  if (value == null) return '';

  final l10n = context.l10n;
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return l10n.communication_justNow;
  if (diff.inMinutes < 60) {
    return l10n.tracking_updatedMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) return l10n.communication_hoursAgo(diff.inHours);
  if (diff.inDays == 1) return l10n.seatRelease_timeYesterday;
  return l10n.seatRelease_timeDaysAgo(diff.inDays);
}
