import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Standing capacity: what the office has to run trips with today.
///
/// One strip replaces the two near-identical panels (fleet, captains) that
/// each carried three tiles and both repeated `activeAssignmentsCount` — the
/// same number, labelled once as buses on the road and once as drivers on the
/// road. Anything here that needs a *decision* (expiring documents, join
/// requests) is raised by the attention panel instead; this is inventory, not
/// a queue.
class FleetTeamSection extends StatelessWidget {
  const FleetTeamSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final fleet = summary.fleetSummary;

    return DashboardPanel(
      icon: DashboardIcons.fleetActive,
      title: 'الأسطول والفريق',
      subtitle: 'الطاقة المتاحة للتشغيل',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.fleet),
        child: const Text('إدارة الأسطول'),
      ),
      child: DashboardKpiGrid(
        itemExtent: 78,
        children: [
          DashboardKpiCard(
            label: 'المركبات',
            value: '${fleet.vehiclesCount}',
            icon: DashboardIcons.fleet,
            color: palette.active,
            onTap: () => onOpenModule(DashboardRoutes.vehicles),
            tapHint: 'فتح المركبات',
          ),
          DashboardKpiCard(
            label: 'السائقون',
            value: '${fleet.driversCount}',
            icon: DashboardIcons.captains,
            color: palette.active,
            onTap: () => onOpenModule(DashboardRoutes.drivers),
            tapHint: 'فتح السائقين',
          ),
          DashboardKpiCard(
            label: 'مهام نشطة',
            value: '${fleet.activeAssignmentsCount}',
            icon: DashboardIcons.routes,
            color: palette.positive,
            onTap: () => onOpenModule(DashboardRoutes.fleet),
            tapHint: 'فتح الأسطول',
          ),
          DashboardKpiCard(
            label: 'مستندات تحتاج متابعة',
            value: '${fleet.documentsNeedFollowUpCount}',
            icon: DashboardIcons.document,
            color: fleet.documentsNeedFollowUpCount > 0
                ? palette.warning
                : palette.neutral,
            onTap: () => onOpenModule(DashboardRoutes.fleet),
            tapHint: 'فتح مستندات الأسطول',
          ),
        ],
      ),
    );
  }
}
