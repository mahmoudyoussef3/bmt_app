import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/conversation.dart';
import '../../utils/communication_labels.dart';
import 'chat_message_content.dart';
import 'chat_message_status_icon.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.category,
  });

  final ChatMessage message;
  final ConversationCategory category;

  /// Group threads name each speaker; one-to-one threads don't need to.
  bool get _showsSenderName =>
      !message.isFromClient &&
      category == ConversationCategory.group &&
      (message.senderName?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isClient = message.isFromClient;

    return Align(
      alignment: isClient
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isClient ? scheme.primary : scheme.surface,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: isClient ? const Radius.circular(16) : Radius.zero,
            bottomEnd: isClient ? Radius.zero : const Radius.circular(16),
          ),
          border: isClient
              ? null
              : Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showsSenderName) ...[
              Text(
                message.senderName!,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: scheme.secondary),
              ),
              const SizedBox(height: 4),
            ],
            ChatMessageContent(message: message, isClient: isClient),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTime(context, message.sentAt),
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: isClient
                        ? scheme.onPrimary.withAlpha(160)
                        : ClientColors.textTertiaryFor(context),
                  ),
                ),
                if (isClient) ...[
                  const SizedBox(width: 4),
                  ChatMessageStatusIcon(message: message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
