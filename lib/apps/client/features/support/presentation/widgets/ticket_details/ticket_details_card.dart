import 'package:flutter/material.dart';

import '../../../domain/entities/support_ticket.dart';
import 'ticket_details_description.dart';
import 'ticket_details_headline.dart';
import 'ticket_details_status_band.dart';

/// The ticket at a glance — headline, status band, and description stacked in
/// one raised card.
class TicketDetailsCard extends StatelessWidget {
  const TicketDetailsCard({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(8),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TicketDetailsHeadline(ticket: ticket),
          TicketDetailsStatusBand(ticket: ticket),
          TicketDetailsDescription(description: ticket.description),
        ],
      ),
    );
  }
}
