import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// An actionable nudge on the hub — an incomplete profile, a package about to
/// lapse. It always carries the action that resolves it, so it is never a
/// dead-end warning.
class ProfileNoticeCard extends StatelessWidget {
  const ProfileNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    const accent = ClientColors.journeyAmber;

    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      decoration: BoxDecoration(
        color: accent.withAlpha(24),
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppLayout.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ClientTypography.labelMedium(context)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppLayout.spaceSm),
                InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(AppLayout.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      actionLabel,
                      style: ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.primaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
