import 'package:flutter/material.dart';

import '../../../domain/entities/conversation.dart';
import 'chat_message_bubble.dart';

/// The message timeline. Owns its scroll controller and follows the thread to
/// the bottom whenever a message arrives.
class ChatMessagesList extends StatefulWidget {
  const ChatMessagesList({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(ChatMessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversation.messages.length !=
        oldWidget.conversation.messages.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.conversation.messages;

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (_, index) => ChatMessageBubble(
        message: messages[index],
        category: widget.conversation.category,
      ),
    );
  }
}
