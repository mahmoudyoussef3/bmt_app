import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/badge.dart';
import 'package:bmt_app/core/widgets/section_header.dart';
import 'package:bmt_app/features/component/presentation/widgets/home/home_mock_data.dart';
import 'package:bmt_app/features/component/presentation/widgets/ui/home_package_card.dart';

/// Refactored Packages section: 
/// - Premium active pass card (if subscribed) showing remaining trips progress.
/// - Sleek horizontal carousel of available package plans.
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
        if (showActivePackage) ...[
          _ActivePackageCard(
            scheme: scheme,
            onTap: onOpenSubscription,
          ),
          const SizedBox(height: AppLayout.spaceLg),
        ],
        
        // Horizontal list of available packages
        SizedBox(
          height: HomePackageCard.cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: plans.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppLayout.spaceMd),
            itemBuilder: (context, index) {
              return HomePackageCard(
                plan: plans[index],
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
  const _ActivePackageCard({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const int remainingTrips = 18;
    const int totalTrips = 30;
    const double progress = remainingTrips / totalTrips;

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
            border: Border.all(
              color: scheme.secondary.withAlpha(80),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                scheme.surface,
                scheme.primary.withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Pass Icon, Title, Active Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Pass',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                        ),
                        Text(
                          'Expires in 12 days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withAlpha(130),
                                fontSize: 11.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const AppBadge(text: 'Active'),
                ],
              ),
              const SizedBox(height: 14),
              
              // Progress Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trips remaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                  ),
                  Text(
                    '$remainingTrips / $totalTrips left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Linear Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: scheme.secondary.withAlpha(25),
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
