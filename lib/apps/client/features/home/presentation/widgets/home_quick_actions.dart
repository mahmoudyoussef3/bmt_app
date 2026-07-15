import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Elevated service tiles that overlap the hero's lower edge —
/// the fastest paths into the app's four main journeys.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onRoutes,
    required this.onTrips,
    required this.onPackages,
    required this.onSupport,
  });

  final VoidCallback onRoutes;
  final VoidCallback onTrips;
  final VoidCallback onPackages;
  final VoidCallback onSupport;

  /// Fixed height so the hero overlap in the home layout stays stable.
  static const double height = 102;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      (
        icon: Icons.route_rounded,
        label: l10n.nav_routes,
        color: ClientColors.primaryFor(context),
        onTap: onRoutes,
      ),
      (
        icon: Icons.confirmation_number_outlined,
        label: l10n.home_myTrips,
        color: ClientColors.journeyCyan,
        onTap: onTrips,
      ),
      (
        icon: Icons.card_membership_rounded,
        label: l10n.home_packagesTitle,
        color: ClientColors.journeyPurple,
        onTap: onPackages,
      ),
      (
        icon: Icons.support_agent_rounded,
        label: l10n.common_support,
        color: ClientColors.journeyAmber,
        onTap: onSupport,
      ),
    ];

    // Clamped so a large system font can't overflow the fixed tile height.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final (index, action) in actions.indexed) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _QuickActionTile(
                  icon: action.icon,
                  label: action.label,
                  color: action.color,
                  onTap: action.onTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          border: Border.all(color: ClientColors.borderFor(context)),
          boxShadow: ClientElevation.sm(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
