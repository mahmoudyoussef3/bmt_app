import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/support_ticket.dart';
import '../../utils/support_status_visuals.dart';
import '../support_ticket_labels.dart';
import 'ticket_assigned_agent_badge.dart';

/// Tinted middle band of the details card: where the ticket currently stands
/// and who is handling it.
class TicketDetailsStatusBand extends StatelessWidget {
  const TicketDetailsStatusBand({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = SupportStatusVisuals.colorFor(context, ticket.status);
    final agentName = ticket.assignedAgentName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        border: Border.symmetric(
          horizontal: BorderSide(color: scheme.outlineVariant.withAlpha(30)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              SupportStatusVisuals.iconFor(ticket.status),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.support_currentStatus,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supportStatusLabel(context, ticket.status),
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (agentName != null) TicketAssignedAgentBadge(agentName: agentName),
        ],
      ),
    );
  }
}
