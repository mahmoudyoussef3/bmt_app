import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/support_ticket.dart';
import 'ticket_details_meta.dart';

/// Top section of the details card: the ticket's title with its category and
/// filing date beneath.
class TicketDetailsHeadline extends StatelessWidget {
  const TicketDetailsHeadline({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.title,
            style: ClientTypography.headingMedium(context).copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              TicketCategoryChip(category: ticket.category),
              TicketCreatedAtLabel(createdAt: ticket.createdAt),
            ],
          ),
        ],
      ),
    );
  }
}
