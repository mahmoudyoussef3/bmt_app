import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_empty_state.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../cubit/communication_cubit.dart';
import '../cubit/communication_state.dart';

class ChatDetailsPage extends StatefulWidget {
  const ChatDetailsPage({
    super.key,
    required this.tripId,
    required this.title,
    this.passengerId,
  });

  final String tripId;
  final String title;
  final String? passengerId;

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CaptainCommunicationCubit>(
      create: (_) =>
          captainGetIt<CaptainCommunicationCubit>()
            ..load(tripId: widget.tripId, passengerId: widget.passengerId),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            Expanded(
              child:
                  BlocBuilder<
                    CaptainCommunicationCubit,
                    CaptainCommunicationState
                  >(
                    builder: (context, state) {
                      if (state is CaptainCommunicationLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is CaptainCommunicationError) {
                        return AsyncStateView(
                          status: AsyncViewStatus.error,
                          errorMessage: state.message,
                          onRetry: () =>
                              context.read<CaptainCommunicationCubit>().load(
                                tripId: widget.tripId,
                                passengerId: widget.passengerId,
                              ),
                          child: const SizedBox.shrink(),
                        );
                      }
                      final messages = state is CaptainCommunicationLoaded
                          ? state.conversation.messages
                          : const <CaptainMessage>[];
                      if (messages.isEmpty) {
                        return const CaptainEmptyState(
                          icon: Icons.forum_outlined,
                          title: 'لا توجد رسائل بعد',
                          subtitle: 'ابدأ المحادثة برسالة قصيرة وواضحة.',
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          16,
                          16,
                          8,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 8,
                            ),
                            child: _MessageBubble(message: message),
                          );
                        },
                      );
                    },
                  ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children:
                    [
                          'أنا في الطريق',
                          'وصلت المحطة',
                          'الرحلة بدأت',
                          'هل أنت في المكان؟',
                          'سأصل خلال 5 دقائق',
                        ]
                        .map(
                          (text) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: ActionChip(
                              label: Text(
                                text,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                _controller.text = text;
                                _controller.selection = TextSelection.collapsed(
                                  offset: text.length,
                                );
                              },
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                      ),
                    ),
                  ),
                  // Voice and image buttons used to sit here. Neither recorded
                  // or attached anything — they posted the literal strings
                  // "Voice note" and "Image shared" into the thread, so the
                  // operator received a message announcing an attachment that
                  // did not exist, and the captain believed they had sent one.
                  // Removed until there is real media upload behind them;
                  // `CaptainMessageType.voice/image` stay in the entity so
                  // existing rows still render.
                  IconButton(
                    tooltip: 'إرسال',
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      context.read<CaptainCommunicationCubit>().send(
                        text,
                        CaptainMessageType.text,
                      );
                      _controller.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CaptainMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mine ? scheme.primary : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: mine ? scheme.primary : scheme.outline.withAlpha(70),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mine ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mine ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
