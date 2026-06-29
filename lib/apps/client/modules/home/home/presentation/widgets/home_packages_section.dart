import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/modules/home/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/modules/home/home/presentation/widgets/home_package_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/core/widgets/section_header.dart';

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
    final cardWidth = width >= 720 ? 248.0 : 226.0;

    final prioritizedPlans = _prioritizePlans(plans);
    final int safeCount = prioritizedPlans.isEmpty
        ? 0
        : previewCount.clamp(1, prioritizedPlans.length).toInt();

    final visiblePlans = prioritizedPlans.take(safeCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Packages preview',
          subtitle: 'Dynamic plans published from the dashboard',
          action: TextButton(
            onPressed: onOpenSubscription,
            child: const Text('See all'),
          ),
        ),
        const SizedBox(height: AppLayout.spaceMd),

        if (activePackage != null) ...[
          _ActivePackageCard(
            scheme: scheme,
            package: activePackage!,
            onTap: onOpenSubscription,
          ),
          const SizedBox(height: AppLayout.spaceLg),
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
              separatorBuilder: (_, separatorIndex) =>
                  const SizedBox(width: AppLayout.spaceMd),
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
            border: Border.all(color: scheme.primary.withAlpha(70), width: 1.3),
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
                          package.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.expiryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
  const _EmptyPackagesCard({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withAlpha(70), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_membership_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Packages are not available yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'When plans are published from the dashboard, weekly and monthly options will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'View packages',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
