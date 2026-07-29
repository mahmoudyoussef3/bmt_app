import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/chat_message.dart';

/// Renders a message's payload by type. Image and voice messages show what the
/// backend recorded about the attachment; neither is playable in-app yet.
class ChatMessageContent extends StatelessWidget {
  const ChatMessageContent({
    super.key,
    required this.message,
    required this.isClient,
  });

  final ChatMessage message;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (message.type) {
      ChatMessageType.image => _ImageContent(
        message: message,
        isClient: isClient,
      ),
      ChatMessageType.voice => _VoiceContent(
        message: message,
        isClient: isClient,
      ),
      ChatMessageType.text => Text(
        message.text,
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: isClient ? scheme.onPrimary : scheme.onSurface),
      ),
    };
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.message, required this.isClient});

  final ChatMessage message;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_rounded,
                    color: ClientColors.textTertiaryFor(context),
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.communication_imagePreviewUnavailable,
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textTertiaryFor(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (message.attachmentName != null)
          Text(
            message.attachmentName!,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: isClient ? scheme.onPrimary : scheme.onSurface),
          ),
        if (message.attachmentSize != null)
          Text(
            message.attachmentSize!,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
      ],
    );
  }
}

class _VoiceContent extends StatelessWidget {
  const _VoiceContent({required this.message, required this.isClient});

  final ChatMessage message;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mic_rounded,
          size: 16,
          color: isClient ? scheme.onPrimary : scheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          message.duration ?? '',
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: isClient ? scheme.onPrimary : scheme.onSurface),
        ),
      ],
    );
  }
}
