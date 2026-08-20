import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// Which vehicles/drivers are actually carrying the fleet's work, and which
/// are sitting idle — answered from real `operation_trips` counts already
/// computed in the datasource (see `FleetVehicle.completedTripsCount` /
/// `FleetDriver.completedTripsCount`), not an invented utilization score.
///
/// Deliberately just a ranked top-5 plus an idle count: a full percentage-
/// utilization metric would need a denominator (hours available? days
/// scheduled?) that nothing in the schema tracks, so this stops at what the
/// trip count can honestly say.
class FleetActivityPanel extends StatelessWidget {
  const FleetActivityPanel({super.key, required this.workspace});

  final FleetWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final vehicles = [...workspace.vehicles]
      ..sort((a, b) => b.completedTripsCount.compareTo(a.completedTripsCount));
    final drivers = [...workspace.drivers]
      ..sort((a, b) => b.completedTripsCount.compareTo(a.completedTripsCount));

    final idleVehicles = workspace.vehicles
        .where(
          (v) =>
              v.status == FleetVehicleStatus.active &&
              v.completedTripsCount == 0,
        )
        .length;
    final idleDrivers = workspace.drivers
        .where(
          (d) =>
              d.status == FleetDriverStatus.active &&
              d.completedTripsCount == 0,
        )
        .length;

    if (vehicles.isEmpty && drivers.isEmpty) return const SizedBox.shrink();

    return DashboardPanel(
      sectionId: DashboardSectionIds.fleetActivity,
      icon: DashboardIcons.trendUp,
      title: 'النشاط التشغيلي',
      subtitle: 'عدد الرحلات المكتملة خلال آخر 12 شهر',
      initiallyExpanded: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vehiclesList = _RankedList(
            title: 'المركبات الأكثر نشاطاً',
            entries: [
              for (final v in vehicles.take(5))
                _RankedEntry(v.vehicleNumber, v.completedTripsCount),
            ],
            idleCount: idleVehicles,
            idleLabel: idleVehicles == 1
                ? 'مركبة نشطة بدون رحلات مكتملة'
                : 'مركبات نشطة بدون رحلات مكتملة',
          );
          final driversList = _RankedList(
            title: 'السائقون الأكثر نشاطاً',
            entries: [
              for (final d in drivers.take(5))
                _RankedEntry(d.fullName, d.completedTripsCount),
            ],
            idleCount: idleDrivers,
            idleLabel: idleDrivers == 1
                ? 'سائق نشط بدون رحلات مكتملة'
                : 'سائقون نشطون بدون رحلات مكتملة',
          );

          if (constraints.maxWidth >= 640) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: vehiclesList),
                const SizedBox(width: AppSpacing.large),
                Expanded(child: driversList),
              ],
            );
          }
          return Column(
            children: [
              vehiclesList,
              const SizedBox(height: AppSpacing.large),
              driversList,
            ],
          );
        },
      ),
    );
  }
}

class _RankedEntry {
  const _RankedEntry(this.label, this.count);
  final String label;
  final int count;
}

class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.title,
    required this.entries,
    required this.idleCount,
    required this.idleLabel,
  });

  final String title;
  final List<_RankedEntry> entries;
  final int idleCount;
  final String idleLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final maxCount = entries.isEmpty ? 0 : entries.first.count;

    if (entries.isEmpty || maxCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'لا توجد رحلات مكتملة بعد لعرض الأكثر نشاطاً.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : entry.count / maxCount,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${entry.count}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (idleCount > 0) ...[
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '$idleCount $idleLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
