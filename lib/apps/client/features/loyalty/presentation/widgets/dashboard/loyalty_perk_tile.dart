import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One benefit of the rider's active tier.
class LoyaltyPerkTile extends StatelessWidget {
  const LoyaltyPerkTile({super.key, required this.perk});

  final String perk;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ClientSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.md,
        vertical: ClientSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: ClientColors.journeyCyan,
            size: 16,
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Text(perk, style: ClientTypography.bodySmall(context)),
          ),
        ],
      ),
    );
  }
}
