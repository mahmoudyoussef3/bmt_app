import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Shown when a ledger or catalog comes back empty — previously these lists
/// rendered a bare heading over nothing, which read as a broken screen.
class LoyaltyEmptyState extends StatelessWidget {
  const LoyaltyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.md,
        vertical: ClientSpacing.xl,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: ClientColors.textTertiaryFor(context)),
          const SizedBox(height: ClientSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ClientTypography.headingSmall(context),
          ),
          const SizedBox(height: ClientSpacing.xxs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}
