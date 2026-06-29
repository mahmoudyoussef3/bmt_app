import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/theme/spacing.dart';

class FleetSummaryCards extends StatelessWidget {
  final FleetSummary summary;

  const FleetSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final followUp = summary.documentsNeedFollowUpCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        final children = [
          _PremiumKpiCard(
            label: 'إجمالي السائقين',
            value: '${summary.driversCount}',
            detail: 'نشط وموقوف',
            icon: Icons.badge_rounded,
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primary.withAlpha(150)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _PremiumKpiCard(
            label: 'إجمالي المركبات',
            value: '${summary.vehiclesCount}',
            detail: 'في الخدمة والصيانة',
            icon: Icons.directions_bus_rounded,
            gradient: LinearGradient(
              colors: [scheme.secondary, scheme.secondary.withAlpha(150)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _PremiumKpiCard(
            label: 'تعيينات نشطة',
            value: '${summary.activeAssignmentsCount}',
            detail: 'مركبات مرتبطة بسائقين',
            icon: Icons.link_rounded,
            gradient: LinearGradient(
              colors: [scheme.tertiary, scheme.tertiary.withAlpha(150)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _PremiumKpiCard(
            label: 'وثائق للمراجعة',
            value: '$followUp',
            detail: 'منتهية أو تقارب الانتهاء',
            icon: Icons.fact_check_rounded,
            gradient: followUp > 0
                ? LinearGradient(
                    colors: [scheme.error, scheme.error.withAlpha(150)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [scheme.primary, scheme.primary.withAlpha(150)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            isAlert: followUp > 0,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: SizedBox(width: double.infinity, height: 140, child: child),
                    ))
                .toList(),
          );
        }

        return GridView.count(
          crossAxisCount: constraints.maxWidth > 1200 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.large,
          crossAxisSpacing: AppSpacing.large,
          childAspectRatio: 2.2,
          children: children,
        );
      },
    );
  }
}

class _PremiumKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final LinearGradient gradient;
  final bool isAlert;

  const _PremiumKpiCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.gradient,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withAlpha(150),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAlert ? scheme.error.withAlpha(100) : scheme.outlineVariant.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withAlpha(5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                  ),
                ),
              ),
              Positioned(
                right: -20,
                top: -20,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 24, color: gradient.colors.first),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                height: 1,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
