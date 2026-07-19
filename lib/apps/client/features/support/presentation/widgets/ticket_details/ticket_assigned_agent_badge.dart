import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Names the customer-service agent handling the ticket. Only rendered once
/// one has actually been assigned.
class TicketAssignedAgentBadge extends StatelessWidget {
  const TicketAssignedAgentBadge({super.key, required this.agentName});

  final String agentName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.l10n.support_assignedTo,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                agentName,
                style: ClientTypography.labelMedium(context).copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
