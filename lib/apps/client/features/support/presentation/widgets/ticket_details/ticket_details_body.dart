import 'package:flutter/material.dart';

import '../../../domain/entities/support_attachment.dart';
import '../../../domain/entities/support_ticket.dart';
import 'ticket_details_agent_note.dart';
import 'ticket_details_app_bar.dart';
import 'ticket_details_attachments.dart';
import 'ticket_details_card.dart';
import 'ticket_details_review_notice.dart';

/// Scrollable content of a loaded ticket.
class TicketDetailsBody extends StatelessWidget {
  const TicketDetailsBody({
    super.key,
    required this.ticket,
    required this.attachments,
  });

  final SupportTicket ticket;
  final List<SupportAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final note = ticket.internalNote;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        TicketDetailsAppBar(
          ticketId: ticket.id,
          ticketNumber: ticket.ticketNumber,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TicketDetailsReviewNotice(status: ticket.status),
                TicketDetailsCard(ticket: ticket),
                if (note != null && note.isNotEmpty)
                  TicketDetailsAgentNote(note: note),
                TicketDetailsAttachments(attachments: attachments),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
