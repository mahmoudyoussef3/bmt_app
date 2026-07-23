import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

import '../../../domain/entities/conversation.dart';
import '../../utils/communication_labels.dart';

/// Names who the rider is talking to and in what capacity, so a thread opened
/// from a notification identifies itself without scrolling.
class ChatThreadAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatThreadAppBar({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Size get preferredSize => const Size.fromHeight(ClientAppBar.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClientAppBar(
      title: conversation.name,
      subtitle: categoryLabel(context, conversation),
      leading: AppAvatar(initials: conversation.initials, radius: 17),
    );
  }
}
