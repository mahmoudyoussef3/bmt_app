import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../cubit/communication_cubit.dart';
import '../../cubit/communication_state.dart';
import 'conversation_filter_chips.dart';
import 'conversation_search_field.dart';
import 'conversation_tile.dart';

/// The conversation hub: search, filter chips, and the thread list.
class ConversationListView extends StatelessWidget {
  const ConversationListView({super.key, required this.state});

  final CommunicationLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = state.visibleConversations;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: ClientAppBar(
        title: context.l10n.communication_chatHubTitle,
        actions: [
          IconButton(
            tooltip: context.l10n.communication_refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<CommunicationCubit>().load(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            ConversationSearchField(hasQuery: state.query.isNotEmpty),
            ConversationFilterChips(selected: state.filter),
            Expanded(
              child: visible.isEmpty
                  ? EmptyState(
                      title: context.l10n.communication_emptyTitle,
                      subtitle: context.l10n.communication_emptySubtitle,
                      emoji: '💬',
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const AppSeparator(),
                      itemBuilder: (_, index) =>
                          ConversationTile(conversation: visible[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
