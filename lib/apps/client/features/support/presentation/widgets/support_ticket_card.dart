import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  Color _getStatusColor(BuildContext context, TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return ClientColors.primaryFor(context);
      case TicketStatus.underReview:
        return ClientColors.journeyAmber;
      case TicketStatus.contacted:
        return ClientColors.secondary;
      case TicketStatus.resolved:
        return ClientColors.journeyCyan;
      case TicketStatus.closed:
        return ClientColors.textTertiaryFor(context);
      case TicketStatus.rejected:
        return ClientColors.journeyRed;
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
    final statusColor = _getStatusColor(context, ticket.status);
    final isUrgent = ticket.priority == TicketPriority.urgent ||
        ticket.priority == TicketPriority.high;

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant.withAlpha(50)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getStatusLabel(ticket.status),
                    style: ClientTypography.labelSmall(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUrgent) ...[
                      Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: ClientColors.journeyRed,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      ticket.ticketNumber,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: scheme.onSurfaceVariant.withAlpha(200),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket.title,
              style: ClientTypography.headingSmall(context).copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant.withAlpha(50)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 16,
                      color: scheme.primary.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ticket.category,
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                      style: ClientTypography.labelMedium(context).copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
