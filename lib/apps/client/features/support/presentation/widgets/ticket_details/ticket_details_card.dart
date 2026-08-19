import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/app_card.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TicketDetailsHeadline(ticket: ticket),
            TicketDetailsStatusBand(ticket: ticket),
            TicketDetailsDescription(description: ticket.description),
          ],
        ),
      ),
    );
  }
}
