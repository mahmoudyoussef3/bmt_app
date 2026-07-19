import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/loyalty_data.dart';
import '../../utils/loyalty_fallback_tier.dart';
import '../../utils/loyalty_labels.dart';
import '../loyalty_section_label.dart';
import 'loyalty_nav_row.dart';
import 'loyalty_perk_tile.dart';
import 'loyalty_progression_card.dart';
import 'loyalty_tier_card.dart';
import 'loyalty_tiers_carousel.dart';

/// The hub's landing panel: tier standing, progress and the two entry points.
class LoyaltyDashboardView extends StatelessWidget {
  const LoyaltyDashboardView({super.key, required this.data});

  final LoyaltyData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tier = data.activeTier ?? fallbackTier(data.currentTierName);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.sm,
        ClientSpacing.md,
        ClientSpacing.xl,
      ),
      children: [
        LoyaltyTierCard(tier: tier, points: data.currentPoints),
        const SizedBox(height: ClientSpacing.md),
        LoyaltyProgressionCard(points: data.currentPoints),
        const SizedBox(height: ClientSpacing.md),
        const LoyaltyNavRow(),
        if (tier.perks.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.lg),
          LoyaltySectionLabel(
            l10n.loyalty_activeTierPerks(tierLabel(context, tier.name)),
          ),
          const SizedBox(height: ClientSpacing.xs),
          ...tier.perks.map((perk) => LoyaltyPerkTile(perk: perk)),
        ],
        const SizedBox(height: ClientSpacing.lg),
        LoyaltySectionLabel(l10n.loyalty_exploreMembership),
        const SizedBox(height: ClientSpacing.xs),
        if (data.tiers.isEmpty)
          Text(
            l10n.loyalty_tiersUnavailable,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          )
        else
          LoyaltyTiersCarousel(
            tiers: data.tiers,
            currentTierName: data.currentTierName,
          ),
      ],
    );
  }
}
