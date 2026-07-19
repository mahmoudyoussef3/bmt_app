import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/loyalty_tier_ladder.dart';

/// Progress toward the top tier.
///
/// Both numbers come from [LoyaltyTierLadder] rather than a threshold typed
/// into the widget, so the bar can never disagree with the tier the rider was
/// actually awarded.
class LoyaltyProgressionCard extends StatelessWidget {
  const LoyaltyProgressionCard({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClientCard(
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.loyalty_nextGoalPlatinum,
                  style: ClientTypography.labelMedium(context),
                ),
              ),
              const SizedBox(width: ClientSpacing.xs),
              Text(
                l10n.loyalty_ptsToGo(LoyaltyTierLadder.pointsToTop(points)),
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.primaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: ClientSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(ClientRadius.xs),
            child: LinearProgressIndicator(
              value: LoyaltyTierLadder.progressToTop(points),
              minHeight: 8,
              backgroundColor: ClientColors.surfaceMutedFor(context),
              color: ClientColors.primaryFor(context),
            ),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            l10n.loyalty_platinumFootnote,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
