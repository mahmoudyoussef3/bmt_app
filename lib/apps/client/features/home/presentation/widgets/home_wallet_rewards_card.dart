import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Wallet balance + rewards points in one home card.
class HomeWalletRewardsCard extends StatelessWidget {
  const HomeWalletRewardsCard({
    super.key,
    required this.onWalletTap,
    required this.onRewardsTap,
  });

  final VoidCallback onWalletTap;
  final VoidCallback onRewardsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onWalletTap,
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppLayout.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet', style: AppTypography.caption(scheme)),
                    const SizedBox(height: 4),
                    Text(
                      'EGP 240.00',
                      style: AppTypography.subheading(
                        scheme,
                      ).copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: scheme.outline.withAlpha(100)),
          Expanded(
            child: InkWell(
              onTap: onRewardsTap,
              borderRadius: BorderRadius.circular(AppLayout.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppLayout.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rewards', style: AppTypography.caption(scheme)),
                    const SizedBox(height: 4),
                    Text(
                      '1,250 pts',
                      style: AppTypography.subheading(
                        scheme,
                      ).copyWith(color: scheme.tertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
