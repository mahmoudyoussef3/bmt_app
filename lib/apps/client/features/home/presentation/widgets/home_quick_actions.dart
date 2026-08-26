import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Elevated service tiles sitting just under the hero's arch —
/// the fastest paths into the app's four main journeys.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onTrips,
    required this.onSubscription,
    required this.onOffices,
    required this.onRoutes,
  });

  final VoidCallback onTrips;

  /// Opens the rider's own subscription. There is no plan catalogue to send
  /// them to: plans live on the office profiles that sell them and are bought
  /// in the booking wizard.
  final VoidCallback onSubscription;
  final VoidCallback onOffices;
  final VoidCallback onRoutes;

  /// Fixed height so the row reads as one band whatever the labels do.
  static const double height = 102;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      (
        icon: Icons.confirmation_number_outlined,
        label: l10n.home_myTrips,
        onTap: onTrips,
      ),
      (
        icon: Icons.card_membership_rounded,
        label: l10n.mySubscription_title,
        onTap: onSubscription,
      ),
      (
        icon: Icons.storefront_rounded,
        label: l10n.home_offices,
        onTap: onOffices,
      ),
      (icon: Icons.route_rounded, label: l10n.nav_routes, onTap: onRoutes),
    ];

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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                // `--primary-tint`, so the wash tracks the token in both
                // themes instead of a fixed alpha that reads as grey on dark.
                color: ClientColors.primaryTintFor(context),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            // Two lines at a legible size rather than one line squeezed to
            // 11sp: a tile is a quarter of the row, and a label like "My
            // Subscription" has no single-line reading of itself that fits.
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ClientTypography.labelSmall(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
