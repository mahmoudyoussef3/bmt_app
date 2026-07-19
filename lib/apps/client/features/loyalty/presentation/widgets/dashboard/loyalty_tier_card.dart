import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/loyalty_tier.dart';
import '../../utils/loyalty_labels.dart';
import '../../utils/loyalty_tier_visuals.dart';
import 'loyalty_tier_card_header.dart';

/// The hero card: the rider's tier branding and points balance.
class LoyaltyTierCard extends StatelessWidget {
  const LoyaltyTierCard({super.key, required this.tier, required this.points});

  final LoyaltyTier tier;
  final int points;

  @override
  Widget build(BuildContext context) {
    final gradient = tier.gradient;

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(ClientSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -20,
            bottom: -20,
            child: Icon(
              tier.icon,
              size: 150,
              color: Colors.white.withAlpha(25),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoyaltyTierCardHeader(
                icon: tier.icon,
                label: context.l10n.loyalty_tierMemberBadge(
                  tierLabel(context, tier.name),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.loyalty_pointsBalanceLabel,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: Colors.white70, letterSpacing: 0.5),
              ),
              const SizedBox(height: ClientSpacing.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$points',
                    style: ClientTypography.displayMedium(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: ClientSpacing.xxs),
                  Text(
                    context.l10n.loyalty_ptsUnit,
                    style: ClientTypography.headingSmall(
                      context,
                    ).copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
