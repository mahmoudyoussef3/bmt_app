import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/redeemable_reward.dart';
import '../../utils/reward_category_visuals.dart';
import 'loyalty_reward_headline.dart';
import 'redeem_reward_action.dart';

/// One catalog reward. Dimmed and inert when the balance can't cover it.
class LoyaltyRewardTile extends StatelessWidget {
  const LoyaltyRewardTile({
    super.key,
    required this.reward,
    required this.balance,
    required this.isEnabled,
  });

  final RedeemableReward reward;
  final int balance;

  /// False while another redemption is in flight, so a rider can't spend the
  /// same points twice by tapping a second reward.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= reward.pointsCost;
    final accent = RewardCategoryVisuals.colorFor(context, reward.category);

    return Opacity(
      opacity: canAfford ? 1 : 0.5,
      child: ClientCard(
        margin: const EdgeInsets.only(bottom: ClientSpacing.sm),
        padding: const EdgeInsets.all(ClientSpacing.md),
        onTap: canAfford && isEnabled
            ? () => redeemRewardFlow(
                context,
                reward: reward,
                balance: balance,
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                RewardCategoryVisuals.iconFor(reward.category),
                color: accent,
                size: 18,
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: LoyaltyRewardHeadline(reward: reward, accent: accent),
            ),
            const SizedBox(width: ClientSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${reward.pointsCost}',
                  style: ClientTypography.priceSmall(context).copyWith(
                    color: canAfford
                        ? ClientColors.journeyAmber
                        : ClientColors.textTertiaryFor(context),
                  ),
                ),
                Text(
                  context.l10n.loyalty_ptsUnit,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
