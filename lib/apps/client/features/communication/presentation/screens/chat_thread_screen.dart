import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../cubit/chat_thread_cubit.dart';
import '../cubit/chat_thread_state.dart';
import '../widgets/chat/chat_input_field.dart';
import '../widgets/chat/chat_messages_list.dart';
import '../widgets/chat/chat_status_bar.dart';
import '../widgets/chat/chat_thread_app_bar.dart';

/// One open conversation, pushed as its own route so the system back gesture
/// and the app bar leave by the same path.
class ChatThreadScreen extends StatelessWidget {
  const ChatThreadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ChatThreadCubit, ChatThreadState>(
      listenWhen: (previous, current) =>
          current is ChatThreadLoaded && current.sendError != null,
      listener: (context, state) {
        final error = (state as ChatThreadLoaded).sendError;
        context.read<ChatThreadCubit>().acknowledgeSendError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error!), backgroundColor: scheme.error),
        );
      },
      builder: (context, state) {
        return switch (state) {
          ChatThreadLoading() => Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: const Center(child: CircularProgressIndicator()),
          ),
          ChatThreadError(:final message) => Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            appBar: ClientAppBar(
              title: context.l10n.communication_chatHubTitle,
            ),
            body: EmptyState(
              title: context.l10n.communication_messagesUnavailable,
              subtitle: message,
            ),
          ),
          ChatThreadLoaded(:final conversation) => Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            appBar: ChatThreadAppBar(conversation: conversation),
            body: SafeArea(
              child: Column(
                children: [
                  ChatStatusBar(conversation: conversation),
                  Expanded(child: ChatMessagesList(conversation: conversation)),
                  const ChatInputField(),
                ],
              ),
            ),
          ),
        };
      },
    );
  }
}
