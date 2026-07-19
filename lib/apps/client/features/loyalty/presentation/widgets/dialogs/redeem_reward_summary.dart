import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/redeemable_reward.dart';

/// Restates which reward is being redeemed, inside the confirmation dialog.
class RedeemRewardSummary extends StatelessWidget {
  const RedeemRewardSummary({super.key, required this.reward});

  final RedeemableReward reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.sm),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars_rounded,
            color: ClientColors.journeyAmber,
            size: 20,
          ),
          const SizedBox(width: ClientSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: ClientTypography.labelMedium(context),
                ),
                Text(
                  context.l10n.loyalty_costPoints(reward.pointsCost),
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
