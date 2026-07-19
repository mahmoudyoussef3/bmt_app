import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/points_transaction.dart';

/// One ledger row. [PointsTransaction.points] is a magnitude, so the sign is
/// rendered from [PointsTransaction.isEarned] alone.
class LoyaltyTransactionTile extends StatelessWidget {
  const LoyaltyTransactionTile({super.key, required this.transaction});

  final PointsTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = transaction.isEarned
        ? ClientColors.journeyCyan
        : ClientColors.journeyRed;
    final sign = transaction.isEarned ? '+' : '-';

    return ClientCard(
      margin: const EdgeInsets.only(bottom: ClientSpacing.xs),
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ClientSpacing.xs),
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isEarned
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: accent,
              size: 16,
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isEmpty
                      ? l10n.loyalty_transactionFallbackTitle
                      : transaction.title,
                  style: ClientTypography.labelMedium(context),
                ),
                if (transaction.date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.date,
                    style: ClientTypography.labelSmall(context).copyWith(
                      color: ClientColors.textTertiaryFor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          Text(
            '$sign${transaction.points} ${l10n.loyalty_ptsUnit}',
            style: ClientTypography.priceSmall(context).copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
