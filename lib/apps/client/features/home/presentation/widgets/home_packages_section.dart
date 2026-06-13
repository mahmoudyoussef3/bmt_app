import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_package_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class HomePackagesSection extends StatelessWidget {
  const HomePackagesSection({
    super.key,
    required this.onOpenSubscription,
    required this.plans,
    this.showActivePackage = true,
    this.previewCount = 3,
  });

  final VoidCallback onOpenSubscription;
  final List<PackagePlanData> plans;
  final bool showActivePackage;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final int safeCount = plans.isEmpty
        ? 0
        : previewCount.clamp(1, plans.length).toInt();

    final visiblePlans = plans.take(safeCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context)!.home_packagesTitle,
          subtitle: AppLocalizations.of(context)!.home_packagesSubtitle,
          action: TextButton(
            onPressed: onOpenSubscription,
            child: Text(AppLocalizations.of(context)!.home_seeAll),
          ),
        ),
        const SizedBox(height: AppLayout.spaceMd),

        if (showActivePackage) ...[
          _ActivePackageCard(
            scheme: scheme,
            onTap: onOpenSubscription,
          ),
          const SizedBox(height: AppLayout.spaceLg),
        ],

        if (visiblePlans.isEmpty)
          _EmptyPackagesCard(
            scheme: scheme,
            onTap: onOpenSubscription,
          )
        else
          SizedBox(
            height: HomePackageCard.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: visiblePlans.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppLayout.spaceMd),
              itemBuilder: (context, index) {
                return HomePackageCard(
                  plan: visiblePlans[index],
                  width: 210,
                  onTap: onOpenSubscription,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ActivePackageCard extends StatelessWidget {
  const _ActivePackageCard({
    required this.scheme,
    required this.onTap,
  });

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const remainingTrips = 18;
    const totalTrips = 30;
    const progress = remainingTrips / totalTrips;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.primary.withAlpha(70),
              width: 1.3,
            ),
            gradient: LinearGradient(
              colors: [
                scheme.primary.withAlpha(20),
                scheme.secondary.withAlpha(12),
                scheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Pass',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Expires in 12 days',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withAlpha(145),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const AppBadge(text: 'Active'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trips remaining',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withAlpha(150),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '$remainingTrips / $totalTrips left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: scheme.primary.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPackagesCard extends StatelessWidget {
  const _EmptyPackagesCard({
    required this.scheme,
    required this.onTap,
  });

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withAlpha(70)),
          ),
          child: Row(
            children: [
              Icon(Icons.card_membership_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No packages available right now',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}