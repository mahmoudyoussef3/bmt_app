import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/loyalty_data.dart';
import '../loyalty_empty_state.dart';
import '../loyalty_section_label.dart';
import 'loyalty_balance_banner.dart';
import 'loyalty_reward_tile.dart';

/// The redemption catalog.
class LoyaltyRewardsView extends StatelessWidget {
  const LoyaltyRewardsView({
    super.key,
    required this.data,
    required this.isRedeeming,
  });

  final LoyaltyData data;
  final bool isRedeeming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.lg,
        ClientSpacing.md,
        ClientSpacing.lg,
        ClientSpacing.xl,
      ),
      children: [
        LoyaltyBalanceBanner(
          points: data.currentPoints,
          tierName: data.currentTierName,
        ),
        const SizedBox(height: ClientSpacing.md),
        LoyaltySectionLabel(l10n.loyalty_catalogRewards),
        const SizedBox(height: ClientSpacing.sm),
        if (data.rewards.isEmpty)
          LoyaltyEmptyState(
            icon: Icons.wallet_giftcard_rounded,
            title: l10n.loyalty_rewardsEmptyTitle,
            body: l10n.loyalty_rewardsEmptyBody,
          )
        else
          ...data.rewards.map(
            (reward) => LoyaltyRewardTile(
              reward: reward,
              balance: data.currentPoints,
              isEnabled: !isRedeeming,
            ),
          ),
      ],
    );
  }
}
