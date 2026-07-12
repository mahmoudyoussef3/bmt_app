import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'support_quick_categories.dart';
import 'support_ticket_card.dart';

/// The Support Center's loaded, non-empty state: category rail up top for
/// quick access to filing a new ticket, followed by the client's existing
/// tickets, newest first (as returned by the backend).
class SupportTicketListView extends StatelessWidget {
  const SupportTicketListView({
    super.key,
    required this.categories,
    required this.tickets,
  });

  final List<String> categories;
  final List<SupportTicket> tickets;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SupportQuickCategories(categories: categories),
        const SizedBox(height: 28),
        Text(
          'My Tickets',
          style: ClientTypography.headingSmall(context).copyWith(
            color: ClientColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
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
