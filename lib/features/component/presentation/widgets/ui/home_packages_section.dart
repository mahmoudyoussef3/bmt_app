import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/home_package_plan_row.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/package_benefits_banner.dart';

/// Packages block: benefits header + plans list in one elevated surface.
class HomePackagesSection extends StatelessWidget {
  const HomePackagesSection({
    super.key,
    required this.onOpenSubscription,
    this.showActivePackage = true,
    this.previewCount = 3,
  });

  final VoidCallback onOpenSubscription;
  final bool showActivePackage;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = previewCount.clamp(1, kPackagePlans.length);
    final plans = kPackagePlans.take(count).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Packages',
          subtitle: 'Built for daily commuters',
          action: TextButton(
            onPressed: onOpenSubscription,
            child: const Text('See all'),
          ),
        ),
        const SizedBox(height: AppLayout.spaceMd),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: onOpenSubscription,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PackageBenefitsBanner(),
                if (showActivePackage)
                  _ActivePackageInset(
                    scheme: scheme,
                    onTap: onOpenSubscription,
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppLayout.spaceSm,
                    bottom: AppLayout.spaceXs,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < plans.length; i++)
                        HomePackagePlanRow(
                          plan: plans[i],
                          featured: i == plans.length - 1,
                          onTap: onOpenSubscription,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.spaceLg,
                    0,
                    AppLayout.spaceLg,
                    AppLayout.spaceMd,
                  ),
                  child: Text(
                    'Tap any plan to compare features and subscribe',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(
                      scheme,
                    ).copyWith(color: scheme.onSurface.withAlpha(140)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivePackageInset extends StatelessWidget {
  const _ActivePackageInset({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.secondary.withAlpha(22),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.spaceLg,
            vertical: AppLayout.spaceMd,
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, size: 18, color: scheme.secondary),
              const SizedBox(width: AppLayout.spaceSm),
              Expanded(
                child: Text(
                  'Your Monthly plan · 18 trips left',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const AppBadge(text: 'Active'),
            ],
          ),
        ),
      ),
    );
  }
}
