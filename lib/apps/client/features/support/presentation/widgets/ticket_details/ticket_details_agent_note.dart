import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The note customer service left on the ticket, called out in amber so it
/// reads as coming from an agent rather than from the client's own submission.
class TicketDetailsAgentNote extends StatelessWidget {
  const TicketDetailsAgentNote({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ClientColors.journeyAmber.withAlpha(25),
            ClientColors.journeyAmber.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.journeyAmber.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ClientColors.journeyAmber.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClientColors.journeyAmber.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: ClientColors.journeyAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.support_customerServiceNote,
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: ClientColors.journeyAmber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            note,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
