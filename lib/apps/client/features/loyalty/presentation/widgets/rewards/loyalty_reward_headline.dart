import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/redeemable_reward.dart';
import '../../utils/loyalty_labels.dart';

/// A reward's title, category chip and description.
class LoyaltyRewardHeadline extends StatelessWidget {
  const LoyaltyRewardHeadline({
    super.key,
    required this.reward,
    required this.accent,
  });

  final RedeemableReward reward;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                reward.title,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(context),
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rewardCategoryLabel(context, reward.category),
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: accent, fontSize: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          reward.description,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}
