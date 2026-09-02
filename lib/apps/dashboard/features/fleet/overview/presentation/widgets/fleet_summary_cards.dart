import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/models/fleet_queue.dart';
import 'package:bmt_app/core/theme/colors.dart';

import 'fleet_format.dart';

/// إدارة الأسطول' headline numbers — the design's four hero KPIs: how many
/// vehicles are ready right now, how many drivers can be put on a trip, how
/// many documents are about to lapse, and how many vehicles are down for
/// maintenance.
///
/// Reads straight off [FleetWorkspace] rather than [FleetWorkspace.summary]:
/// the summary carries the older totals/active-assignments numbers this
/// redesign replaced, and has no readiness count of its own.
///
/// ## Every tile lands on rows that add up to it
///
/// "١٩ مركبة جاهزة" is only useful if the next question — *which nineteen* —
/// is one press away, and the rows that open must be exactly the ones the
/// number counted. Each jump below therefore reuses the very predicate the
/// tile counted with ([FleetVehicleQueue.available] and friends), so the tile,
/// the tab it opens and the queue behind them cannot disagree.
///
/// «مستندات تنتهي» is the one tile with no jump. Its number spans drivers *and*
/// vehicles, and no single tab holds both, so any destination would show fewer
/// rows than the tile claims. A tile that under-delivers on its own count is
/// worse than one that simply does not move — the «يحتاج انتباهك» panel below
/// is where that follow-up actually lives.
class FleetSummaryCards extends StatelessWidget {
  const FleetSummaryCards({super.key, required this.workspace, this.onJump});

  final FleetWorkspace workspace;

  /// Opens the queue a tile counted. Optional so the strip stays renderable in
  /// a harness with no tab host above it.
  final ValueChanged<FleetKpiJump>? onJump;

  @override
  Widget build(BuildContext context) {
    final readyVehicles = FleetVehicleQueue.available.countIn(
      workspace.vehicles,
      workspace,
    );
    // What the drivers tab's «متاح الآن» queue will actually show, not
    // `status == active`: an active driver whose licence lapsed yesterday is
    // not someone this office can put on a bus, and the two numbers must be
    // the same number.
    final readyDrivers = FleetDriverQueue.available.countIn(
      workspace.drivers,
      workspace,
    );
    final expiringDocuments = workspace.summary.documentsNeedFollowUpCount;
    final inMaintenance = workspace.vehicles
        .where((vehicle) => vehicle.status == FleetVehicleStatus.maintenance)
        .length;

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: [
        _tile(
          context,
          label: 'مركبات جاهزة',
          value: readyVehicles,
          detail: 'من ${FleetFormat.count(workspace.vehicles.length)} مركبة',
          icon: Icons.local_shipping_outlined,
          tone: AppStatusTone.success,
          hint: 'عرض المركبات المتاحة الآن',
          jump: const FleetKpiJump(
            tab: FleetTab.vehicles,
            vehicleQueue: FleetVehicleQueue.available,
          ),
        ),
        _tile(
          context,
          label: 'سائقون جاهزون',
          value: readyDrivers,
          detail: 'من ${FleetFormat.count(workspace.drivers.length)} سائقاً',
          icon: Icons.badge_outlined,
          tone: AppStatusTone.info,
          hint: 'عرض السائقين المتاحين الآن',
          jump: const FleetKpiJump(
            tab: FleetTab.drivers,
            driverQueue: FleetDriverQueue.available,
          ),
        ),
        _tile(
          context,
          label: 'مستندات تنتهي',
          value: expiringDocuments,
          detail: 'للسائقين والمركبات معاً',
          icon: Icons.description_outlined,
          // The tiles that change colour with their own number: an empty
          // follow-up list is the good news, and saying so in red would train
          // the operator to stop reading it.
          tone: expiringDocuments > 0
              ? AppStatusTone.warning
              : AppStatusTone.neutral,
          hint: null,
          jump: null,
        ),
        _tile(
          context,
          label: 'في الصيانة',
          value: inMaintenance,
          detail: 'مركبات خارج الخدمة',
          icon: Icons.build_outlined,
          tone: inMaintenance > 0 ? AppStatusTone.error : AppStatusTone.neutral,
          hint: 'عرض المركبات في الصيانة',
          jump: const FleetKpiJump(
            tab: FleetTab.vehicles,
            vehicleRecordStatus: FleetVehicleStatus.maintenance,
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    required int value,
    required String detail,
    required IconData icon,
    required AppStatusTone tone,
    required String? hint,
    required FleetKpiJump? jump,
  }) {
    final jumper = onJump;
    return DashboardKpiCard(
      label: label,
      value: FleetFormat.count(value),
      detail: detail,
      icon: icon,
      // The tone's `accent`, not its `ink`: a tile's fill is near-white, and
      // `ink` is the *container* ink, which on it reads as black type rather
      // than as a status.
      color: DashboardColors.status(context, tone).accent,
      emphasized: true,
      onTap: (jump == null || jumper == null) ? null : () => jumper(jump),
      tapHint: jump == null ? null : hint,
    );
  }
}
