import 'package:flutter/material.dart';

import '../../../domain/entities/support_attachment.dart';
import '../../../domain/entities/support_ticket.dart';
import 'ticket_details_agent_note.dart';
import 'ticket_details_app_bar.dart';
import 'ticket_details_attachments.dart';
import 'ticket_details_card.dart';
import 'ticket_details_review_notice.dart';

/// Scrollable content of a loaded ticket.
class TicketDetailsBody extends StatefulWidget {
  const TicketDetailsBody({
    super.key,
    required this.ticket,
    required this.attachments,
  });

  final SupportTicket ticket;
  final List<SupportAttachment> attachments;

  @override
  State<TicketDetailsBody> createState() => _TicketDetailsBodyState();
}

class _TicketDetailsBodyState extends State<TicketDetailsBody> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        (index * 0.1 + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final attachments = widget.attachments;
    final note = ticket.internalNote;

    int itemIndex = 0;

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
                _buildAnimatedItem(TicketDetailsReviewNotice(status: ticket.status), itemIndex++),
                _buildAnimatedItem(TicketDetailsCard(ticket: ticket), itemIndex++),
                if (note != null && note.isNotEmpty)
                  _buildAnimatedItem(TicketDetailsAgentNote(note: note), itemIndex++),
                _buildAnimatedItem(TicketDetailsAttachments(attachments: attachments), itemIndex++),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
