import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../../../domain/entities/chat_message.dart';

/// Delivery marker on the client's own messages: in flight, delivered, or
/// failed. Only [ChatMessageStatus.sent] consults the read receipt.
class ChatMessageStatusIcon extends StatelessWidget {
  const ChatMessageStatusIcon({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (message.status) {
      ChatMessageStatus.sending => Icon(
        Icons.schedule_rounded,
        size: 11,
        color: scheme.onPrimary.withAlpha(160),
      ),
      ChatMessageStatus.failed => const Icon(
        Icons.error_outline_rounded,
        size: 11,
        color: ClientColors.journeyRed,
      ),
      ChatMessageStatus.sent => Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 11,
        color: message.isRead
            ? ClientColors.journeyCyan
            : scheme.onPrimary.withAlpha(160),
      ),
    };
  }
}
