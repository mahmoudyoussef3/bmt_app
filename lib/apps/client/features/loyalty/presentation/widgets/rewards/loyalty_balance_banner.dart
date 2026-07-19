import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../utils/loyalty_labels.dart';

/// Spendable balance, plus the rider's *actual* tier — this badge used to read
/// "Gold Level Member" for everyone regardless of what they had earned.
class LoyaltyBalanceBanner extends StatelessWidget {
  const LoyaltyBalanceBanner({
    super.key,
    required this.points,
    required this.tierName,
  });

  final int points;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = ClientColors.primaryFor(context);

    return ClientCard(
      padding: const EdgeInsets.all(ClientSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loyalty_redeemableBalance,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
              const SizedBox(height: ClientSpacing.xxs),
              Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: ClientColors.journeyAmber,
                    size: 18,
                  ),
                  const SizedBox(width: ClientSpacing.xxs),
                  Text(
                    '$points ${l10n.loyalty_ptsUnit}',
                    style: ClientTypography.priceMedium(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: ClientSpacing.xs),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClientSpacing.xs,
                vertical: ClientSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: primary.withAlpha(24),
                borderRadius: BorderRadius.circular(ClientRadius.xs),
              ),
              child: Text(
                l10n.loyalty_tierLevelMember(tierLabel(context, tierName)),
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
