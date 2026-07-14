import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'support_home_header.dart';
import 'support_ticket_card.dart';

/// The Support Center's loaded, non-empty state: the hero (which owns the
/// "Create a ticket" action) followed by the client's tickets, newest first
/// as returned by the backend.
class SupportTicketListView extends StatelessWidget {
  const SupportTicketListView({
    super.key,
    required this.tickets,
    required this.onCreateTicket,
  });

  final List<SupportTicket> tickets;
  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SupportHomeHeader(onCreateTicket: onCreateTicket),
        const SizedBox(height: 28),
        _SectionTitle(count: tickets.length),
        const SizedBox(height: 16),
        for (final ticket in tickets) ...[
          SupportTicketCard(
            ticket: ticket,
            onTap: () => Navigator.pushNamed(
              context,
              ClientRoutes.ticketDetails,
              arguments: ticket.id,
            ),
          ),
          if (ticket != tickets.last) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'My tickets',
          style: ClientTypography.headingSmall(context).copyWith(
            color: ClientColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ClientColors.primaryContainerFor(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.primaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
