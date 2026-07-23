import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// Readiness breakdown of the fleet: how many drivers can take a trip right
/// now, and what state the vehicles are in.
///
/// Built from the already-loaded workspace — no extra query — and rendered with
/// the shared panel/donut/palette so it matches every other chart in the
/// dashboard instead of carrying its own colours and card style.
class FleetAnalyticsCharts extends StatelessWidget {
  const FleetAnalyticsCharts({super.key, required this.workspace});

  final FleetWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final drivers = DashboardPanel(
      icon: Icons.people_alt_rounded,
      title: 'جاهزية السائقين',
      subtitle: 'من يمكنه استلام رحلة الآن',
      child: DashboardDonutChart(data: _driverData()),
    );

    final vehicles = DashboardPanel(
      icon: Icons.directions_bus_rounded,
      title: 'حالة المركبات',
      subtitle: 'توزيع الأسطول حسب الحالة التشغيلية',
      child: DashboardDonutChart(data: _vehicleData()),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              drivers,
              const SizedBox(height: AppSpacing.medium),
              vehicles,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: drivers),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: vehicles),
          ],
        );
      },
    );
  }

  List<ChartDatum> _driverData() {
    var available = 0;
    var assigned = 0;
    var needsAttention = 0;
    var suspended = 0;

    for (final driver in workspace.drivers) {
      if (driver.status == FleetDriverStatus.suspended) {
        suspended++;
        continue;
      }
      final snapshot = DriverOperations.snapshot(driver, workspace);
      if (snapshot.canAssign) {
        available++;
      } else if (snapshot.status == DriverOperationalStatus.assigned) {
        assigned++;
      } else if (snapshot.requiresAttention) {
        needsAttention++;
      }
    }

    return _nonEmpty([
      ('متاح للإسناد', available, DashboardChartPalette.positive),
      ('مُعيَّن على مركبة', assigned, DashboardChartPalette.active),
      ('يحتاج متابعة', needsAttention, DashboardChartPalette.warning),
      ('موقوف', suspended, DashboardChartPalette.negative),
    ]);
  }

  List<ChartDatum> _vehicleData() {
    var active = 0;
    var maintenance = 0;
    var suspended = 0;
    var archived = 0;

    for (final vehicle in workspace.vehicles) {
      switch (vehicle.status) {
        case FleetVehicleStatus.active:
          active++;
        case FleetVehicleStatus.maintenance:
          maintenance++;
        case FleetVehicleStatus.suspended:
          suspended++;
        case FleetVehicleStatus.archived:
          archived++;
      }
    }

    return _nonEmpty([
      ('في الخدمة', active, DashboardChartPalette.positive),
      ('في الصيانة', maintenance, DashboardChartPalette.warning),
      ('موقوفة', suspended, DashboardChartPalette.negative),
      ('مؤرشفة', archived, DashboardChartPalette.neutral),
    ]);
  }

  /// Drops zero-valued categories so the legend lists only what actually exists.
  List<ChartDatum> _nonEmpty(List<(String, int, Color)> entries) {
    return [
      for (final (label, value, color) in entries)
        if (value > 0)
          ChartDatum(label: label, value: value.toDouble(), color: color),
    ];
  }
}
