import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
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
                      final messages = state is CaptainCommunicationLoaded
                          ? state.conversation.messages
                          : const <CaptainMessage>[];
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${message.senderName}: ${message.text}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message passenger',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send text',
                    onPressed: () {
                      context.read<CaptainCommunicationCubit>().send(
                        _controller.text,
                        CaptainMessageType.text,
                      );
                      _controller.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                  IconButton(
                    tooltip: 'Send voice note',
                    onPressed: () => context
                        .read<CaptainCommunicationCubit>()
                        .send('Voice note', CaptainMessageType.voice),
                    icon: const Icon(Icons.mic_rounded),
                  ),
                  IconButton(
                    tooltip: 'Send image',
                    onPressed: () => context
                        .read<CaptainCommunicationCubit>()
                        .send('Image shared', CaptainMessageType.image),
                    icon: const Icon(Icons.image_rounded),
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
