import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/conversation.dart';
import '../../utils/communication_labels.dart';

/// Category and complaint status strip above the message timeline.
class ChatStatusBar extends StatelessWidget {
  const ChatStatusBar({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 14,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 6),
              Text(
                categoryLabel(context, conversation),
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ClientColors.journeyAmber.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel(context, conversation.status),
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.journeyAmber),
            ),
          ),
        ],
      ),
    );
  }
}
