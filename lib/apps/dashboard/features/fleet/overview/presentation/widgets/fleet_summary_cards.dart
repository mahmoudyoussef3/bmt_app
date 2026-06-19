import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

class FleetSummaryCards extends StatelessWidget {
  final FleetSummary summary;

  const FleetSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final followUp = summary.documentsNeedFollowUpCount;

    return DashboardKpiGrid(
      itemExtent: 88,
      children: [
        DashboardKpiCard(
          label: 'السائقين',
          value: '${summary.driversCount}',
          detail: 'إجمالي المسجلين',
          icon: Icons.badge_outlined,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          label: 'المركبات',
          value: '${summary.vehiclesCount}',
          detail: 'جاهزة أو تحت المتابعة',
          icon: Icons.directions_bus_outlined,
          color: scheme.secondary,
        ),
        DashboardKpiCard(
          label: 'التعيينات',
          value: '${summary.activeAssignmentsCount}',
          detail: 'تعيينات نشطة الآن',
          icon: Icons.link_rounded,
          color: scheme.tertiary,
        ),
        DashboardKpiCard(
          label: 'الوثائق',
          value: '$followUp',
          detail: 'تحتاج مراجعة',
          icon: Icons.fact_check_outlined,
          color: followUp > 0 ? scheme.error : scheme.primary,
        ),
      ],
    );
  }
}
