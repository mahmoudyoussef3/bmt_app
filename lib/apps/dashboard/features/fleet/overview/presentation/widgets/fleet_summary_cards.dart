import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// Fleet headline numbers — the "isTable" mock's four hero KPIs: how many
/// vehicles are ready right now, how many drivers are on duty, how many
/// documents are about to lapse, and how many vehicles are down for
/// maintenance.
///
/// Reads straight off [FleetWorkspace] rather than [FleetWorkspace.summary]:
/// the summary only carries the older totals/active-assignments/follow-up
/// numbers this redesign replaced, and has no readiness or maintenance count
/// of its own.
class FleetSummaryCards extends StatelessWidget {
  final FleetWorkspace workspace;

  const FleetSummaryCards({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    final readyVehicles = workspace.vehicles
        .where(
          (vehicle) =>
              workspace.operationalStatusOf(vehicle) ==
              FleetOperationalStatus.available,
        )
        .length;
    final onDutyDrivers = workspace.drivers
        .where((driver) => driver.status == FleetDriverStatus.active)
        .length;
    final expiringDocuments = workspace.summary.documentsNeedFollowUpCount;
    final inMaintenance = workspace.vehicles
        .where((vehicle) => vehicle.status == FleetVehicleStatus.maintenance)
        .length;

    return DashboardKpiGrid(
      itemExtent: 116,
      children: [
        DashboardKpiCard(
          emphasized: true,
          label: 'مركبات جاهزة',
          value: '$readyVehicles',
          detail: 'من ${workspace.vehicles.length}',
          icon: Icons.local_shipping_rounded,
          color: palette.active,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'سائقون في الخدمة',
          value: '$onDutyDrivers',
          detail: 'من ${workspace.drivers.length}',
          icon: Icons.badge_rounded,
          color: palette.positive,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'مستندات تنتهي',
          value: '$expiringDocuments',
          detail: 'خلال ٣٠ يوماً',
          icon: Icons.description_rounded,
          color: expiringDocuments > 0 ? palette.negative : palette.neutral,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'في الصيانة',
          value: '$inMaintenance',
          detail: 'مركبات',
          icon: Icons.build_rounded,
          color: inMaintenance > 0 ? palette.negative : palette.neutral,
        ),
      ],
    );
  }
}
