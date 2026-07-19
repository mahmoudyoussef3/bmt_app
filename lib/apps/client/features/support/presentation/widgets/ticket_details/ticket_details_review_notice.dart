import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/support_ticket.dart';

/// Reassurance banner shown while a ticket is still waiting on customer
/// service. Once an agent has contacted the client — or the ticket has been
/// resolved, closed or rejected — the notice no longer applies and collapses.
class TicketDetailsReviewNotice extends StatelessWidget {
  const TicketDetailsReviewNotice({super.key, required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != TicketStatus.submitted &&
        status != TicketStatus.underReview) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.l10n.support_reviewingNotice,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
