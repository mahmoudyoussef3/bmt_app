import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import '../../domain/entities/support_ticket.dart';

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return ClientColors.primary;
      case TicketStatus.underReview:
        return ClientColors.journeyAmber;
      case TicketStatus.contacted:
        return ClientColors.secondary;
      case TicketStatus.resolved:
        return ClientColors.journeyGreen;
      case TicketStatus.closed:
        return Colors.grey.shade600;
      case TicketStatus.rejected:
        return Colors.red.shade600;
    }
  }

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return 'Submitted';
      case TicketStatus.underReview:
        return 'Under Review';
      case TicketStatus.contacted:
        return 'Contacted';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(ticket.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketNumber,
                  style: ClientTypography.labelMedium(context).copyWith(
                    color: scheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(ticket.status),
                    style: ClientTypography.labelSmall(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.title,
              style: ClientTypography.headingSmall(context).copyWith(
                color: scheme.onSurface,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.category,
              style: ClientTypography.bodySmall(context).copyWith(
                color: scheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outline.withAlpha(40), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: scheme.onSurface.withAlpha(130)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(ticket.createdAt),
                  style: ClientTypography.labelMedium(context).copyWith(
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
