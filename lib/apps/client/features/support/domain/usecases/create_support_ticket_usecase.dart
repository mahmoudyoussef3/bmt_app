import 'dart:math';

import '../entities/support_ticket.dart';

class CreateSupportTicketUseCase {
  CreateSupportTicketUseCase({Random? random}) : _random = random ?? Random();

  final Random _random;

  SupportTicket call({
    required String category,
    required String title,
    required String description,
    required String priority,
    required bool imageAttached,
  }) {
    return SupportTicket(
      id: '#TK-${_random.nextInt(9000) + 1000}',
      category: category,
      title: title,
      description: description,
      priority: priority,
      status: TicketStatus.open,
      dateCreated: 'Today, Jun 3',
      attachedImages: imageAttached
          ? const ['uploaded_issue_photo.png']
          : const [],
      conversation: [
        {'sender': 'user', 'text': description, 'time': 'Just now'},
      ],
    );
  }
}
