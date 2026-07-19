import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/conversation.dart';
import '../../utils/communication_labels.dart';

class ConversationCategoryBadge extends StatelessWidget {
  const ConversationCategoryBadge({super.key, required this.conversation});

  final Conversation conversation;

  static Color colorFor(ConversationCategory category, ColorScheme scheme) {
    return switch (category) {
      ConversationCategory.driver => scheme.secondary,
      ConversationCategory.support => scheme.error,
      ConversationCategory.group => ClientColors.journeyCyan,
      ConversationCategory.other => ClientColors.journeySlate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(
      conversation.category,
      Theme.of(context).colorScheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        categoryLabel(context, conversation),
        style: ClientTypography.labelSmall(context).copyWith(color: color),
      ),
    );
  }
}
