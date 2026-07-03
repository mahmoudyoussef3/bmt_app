import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_package_card.dart';

import 'package:bmt_app/core/widgets/badge.dart';

class HomePackagesSection extends StatelessWidget {
  const HomePackagesSection({
    super.key,
    required this.onOpenSubscription,
    required this.plans,
    this.activePackage,
    this.previewCount = 3,
  });

  final VoidCallback onOpenSubscription;
  final List<PackagePlanData> plans;
  final HomeActivePackageData? activePackage;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 720 ? 280.0 : 250.0;

    final prioritizedPlans = _prioritizePlans(plans);
    final int safeCount = prioritizedPlans.isEmpty
        ? 0
        : previewCount.clamp(1, prioritizedPlans.length).toInt();

    final visiblePlans = prioritizedPlans.take(safeCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Packages',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save on frequent rides',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenSubscription,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.primary,
              ),
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (activePackage != null) ...[
          _ActivePackageCard(
            scheme: scheme,
            package: activePackage!,
            onTap: onOpenSubscription,
          ),
          const SizedBox(height: 32),
        ],

        if (visiblePlans.isEmpty)
          _EmptyPackagesCard(scheme: scheme, onTap: onOpenSubscription)
        else
          SizedBox(
            height: HomePackageCard.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: visiblePlans.length,
              separatorBuilder: (_, separatorIndex) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return HomePackageCard(
                  plan: visiblePlans[index],
                  width: cardWidth,
                  onTap: onOpenSubscription,
                );
              },
            ),
          ),
      ],
    );
  }

  List<PackagePlanData> _prioritizePlans(List<PackagePlanData> source) {
    const order = ['weekly', 'two', 'three', 'month'];
    final remaining = [...source];
    final ordered = <PackagePlanData>[];

    for (final key in order) {
      final index = remaining.indexWhere((plan) {
        final text = '${plan.title} ${plan.subtitle}'.toLowerCase();
        if (key == 'three') {
          return text.contains('three') || text.contains('3 month');
        }
        if (key == 'month') {
          return (text.contains('monthly') || text.contains('month')) &&
              !text.contains('three') &&
              !text.contains('3 month');
        }
        return text.contains(key);
      });
      if (index != -1) ordered.add(remaining.removeAt(index));
    }

    ordered.addAll(remaining);
    return ordered;
  }
}

class _ActivePackageCard extends StatelessWidget {
  const _ActivePackageCard({
    required this.scheme,
    required this.package,
    required this.onTap,
  });

  final ColorScheme scheme;
  final HomeActivePackageData package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remainingTrips = package.remainingTrips;
    final totalTrips = package.totalTrips;
    final progress = totalTrips > 0 ? remainingTrips / totalTrips : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? scheme.outline.withAlpha(40) : scheme.outline.withAlpha(60),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_membership_rounded,
                        color: scheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package.expiryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withAlpha(160),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const AppBadge(text: 'ACTIVE'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Trips',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withAlpha(160),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '$remainingTrips / $totalTrips',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.primary.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPackagesCard extends StatelessWidget {
  const _EmptyPackagesCard({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.local_activity_outlined, color: scheme.primary.withAlpha(150), size: 32),
              const SizedBox(height: 16),
              Text(
                'No Packages Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new subscription plans and savings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
