import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_surface.dart';
import 'package:bmt_app/core/widgets/badge.dart';

/// Compact active package summary for home.
class HomePackageSummaryCard extends StatelessWidget {
  const HomePackageSummaryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      radius: AppLayout.radiusLg,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppLayout.spaceSm),
            decoration: BoxDecoration(
              color: scheme.secondary.withAlpha(40),
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
            ),
            child: Icon(Icons.card_membership_rounded, color: scheme.secondary),
          ),
          const SizedBox(width: AppLayout.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Monthly package',
                      style: AppTypography.subheading(scheme),
                    ),
                    const SizedBox(width: AppLayout.spaceSm),
                    const AppBadge(text: 'Active'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '18 trips left · Renews Jul 1',
                  style: AppTypography.caption(scheme),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface.withAlpha(140),
          ),
        ],
      ),
    );
  }
}
