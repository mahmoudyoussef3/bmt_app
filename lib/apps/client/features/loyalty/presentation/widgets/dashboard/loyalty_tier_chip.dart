import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/loyalty_tier.dart';
import '../../utils/loyalty_labels.dart';
import '../../utils/loyalty_tier_visuals.dart';

/// One membership level in the explore carousel.
class LoyaltyTierChip extends StatelessWidget {
  const LoyaltyTierChip({
    super.key,
    required this.tier,
    required this.isCurrent,
  });

  final LoyaltyTier tier;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsetsDirectional.only(end: ClientSpacing.xs),
      padding: const EdgeInsets.all(ClientSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tier.gradient),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(
          color: isCurrent ? Colors.white : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(tier.icon, size: 16, color: Colors.white),
              const SizedBox(width: ClientSpacing.xxs),
              Flexible(
                child: Text(
                  tierLabel(context, tier.name),
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClientSpacing.xxs),
          Text(
            isCurrent
                ? context.l10n.loyalty_currentTier
                : context.l10n.loyalty_needsPoints(tier.pointsRequiredLabel),
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
