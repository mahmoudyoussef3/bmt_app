import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Fleet headline numbers.
///
/// Uses the shared KPI tiles rather than the bespoke gradient/glass cards this
/// module used to carry: those were the only cards of their kind in the
/// dashboard, they stacked two `BackdropFilter`s per tile (one of them blurring
/// a fully transparent box, so pure cost for no pixels), and their label sat in
/// an unconstrained `Row` that clipped on narrow columns.
class FleetSummaryCards extends StatelessWidget {
  final FleetSummary summary;

  const FleetSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final followUp = summary.documentsNeedFollowUpCount;

    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'إجمالي السائقين',
          detail: 'نشط وموقوف',
          value: '${summary.driversCount}',
          icon: Icons.badge_rounded,
          color: palette.active,
        ),
        DashboardKpiCard(
          label: 'إجمالي المركبات',
          detail: 'في الخدمة والصيانة',
          value: '${summary.vehiclesCount}',
          icon: Icons.directions_bus_rounded,
          color: palette.accent,
        ),
        DashboardKpiCard(
          label: 'تعيينات نشطة',
          detail: 'مركبات مرتبطة بسائقين',
          value: '${summary.activeAssignmentsCount}',
          icon: Icons.link_rounded,
          color: palette.positive,
        ),
        DashboardKpiCard(
          label: 'وثائق للمراجعة',
          detail: 'منتهية أو تقارب الانتهاء',
          value: '$followUp',
          icon: Icons.fact_check_rounded,
          // Only reads as an alert when there is actually something to chase.
          color: followUp > 0 ? palette.negative : palette.neutral,
        ),
      ],
    );
  }
}
