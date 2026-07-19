import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../cubit/communication_cubit.dart';
import '../cubit/communication_state.dart';
import '../widgets/conversation_list/conversation_list_view.dart';

/// Support chat hub: the client's conversation list. Opening a thread pushes
/// `CommunicationRoutes.chatThread` rather than swapping the body, so back
/// behaves like every other route in the app.
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;

        return switch (state) {
          CommunicationLoading() => Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: const Center(child: CircularProgressIndicator()),
          ),
          CommunicationError(:final message) => Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: EmptyState(
              title: context.l10n.communication_messagesUnavailable,
              subtitle: message,
            ),
          ),
          CommunicationLoaded loaded => ConversationListView(state: loaded),
        };
      },
    );
  }
}
