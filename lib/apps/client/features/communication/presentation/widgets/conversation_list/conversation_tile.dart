import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../../domain/entities/conversation.dart';
import '../../cubit/communication_cubit.dart';
import '../../routes/chat_thread_arguments.dart';
import '../../routes/communication_routes.dart';
import '../../utils/communication_labels.dart';
import 'conversation_category_badge.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation});

  final Conversation conversation;

  /// Opens the thread, then re-reads the list so this tile's preview reflects
  /// anything sent while it was open.
  Future<void> _open(BuildContext context) async {
    final cubit = context.read<CommunicationCubit>();
    await Navigator.pushNamed(
      context,
      CommunicationRoutes.chatThread,
      arguments: ChatThreadArguments(
        conversationId: conversation.id,
      ).toArguments(),
    );
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AppAvatar(initials: conversation.initials, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleRow(conversation: conversation),
                    const SizedBox(height: 4),
                    _PreviewRow(conversation: conversation),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            conversation.name,
            style: ClientTypography.labelLarge(context),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          displayTime(context, conversation.updatedAt),
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConversationCategoryBadge(conversation: conversation),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            conversation.lastMessage,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
