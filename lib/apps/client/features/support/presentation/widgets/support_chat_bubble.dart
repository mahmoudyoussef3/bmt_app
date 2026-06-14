import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/support_message.dart';

class SupportChatBubble extends StatelessWidget {
  const SupportChatBubble({
    super.key,
    required this.message,
  });

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isClient = message.senderType == MessageSenderType.client;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isClient)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                message.senderType == MessageSenderType.system 
                    ? Icons.android 
                    : Icons.support_agent, 
                size: 16, 
                color: Theme.of(context).primaryColor
              ),
            ),
          if (!isClient) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isClient ? Theme.of(context).primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isClient ? 16 : 4),
                  bottomRight: Radius.circular(isClient ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isClient ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (message.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: message.attachments.map((a) => InkWell(
                          onTap: () {
                            // TODO: Implement image viewer / file downloader
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file, size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    a.fileName,
                                    style: TextStyle(
                                      color: isClient ? Colors.white : Colors.black87,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      color: isClient ? Colors.white70 : Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isClient) const SizedBox(width: 8),
          if (isClient)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
