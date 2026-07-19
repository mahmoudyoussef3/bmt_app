import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The tier card's top row: the membership chip and the programme wordmark.
class LoyaltyTierCardHeader extends StatelessWidget {
  const LoyaltyTierCardHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClientSpacing.xs,
              vertical: ClientSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(ClientRadius.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: ClientSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: ClientSpacing.xs),
        Text(
          context.l10n.loyalty_megaLoyaltyBadge,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: Colors.white, letterSpacing: 0.8),
        ),
      ],
    );
  }
}
