import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Standing capacity: what the office has to run trips with today.
///
/// Two readings, in the order they are asked. **Where the buses are** —
/// [FleetSummary.inServiceVehiclesCount] / `unassignedVehiclesCount` /
/// `inMaintenanceVehiclesCount` already partition every non-archived vehicle
/// exactly once (see `FleetWorkspace.summary`), so the three bars always add up
/// to the fleet total and the split is a real one rather than three tallies
/// that happen to share a panel. **Who and how many** — the roster totals
/// underneath: drivers, buses, live pairings.
///
/// The roster line is why the panel can honestly be called الأسطول والفريق
/// again. It reported vehicles only for a while, under a title that promised
/// the team too, and an operator asking "do I have drivers for tomorrow" got no
/// answer from the screen that claimed to be about exactly that.
///
/// Anything here that needs a *decision* (expiring documents, join requests) is
/// raised by the attention panel instead; this is inventory, not a queue.
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
    final total = fleet.vehiclesCount;

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeFleetTeam,
      icon: DashboardIcons.fleetActive,
      title: 'الأسطول والفريق',
      subtitle: total == 0 ? null : 'الطاقة المتاحة للتشغيل',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.fleet),
        child: const Text('التفاصيل'),
      ),
      child: total == 0
          ? Text(
              'لا مركبات مسجلة بعد.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            )
          : Column(
              children: [
                _FleetStatusRow(
                  label: 'في الخدمة',
                  count: fleet.inServiceVehiclesCount,
                  total: total,
                  color: palette.positive,
                  onTap: () => onOpenModule(DashboardRoutes.vehicles),
                ),
                const SizedBox(height: AppSpacing.medium),
                _FleetStatusRow(
                  label: 'بلا تعيين',
                  count: fleet.unassignedVehiclesCount,
                  total: total,
                  color: palette.active,
                  onTap: () => onOpenModule(DashboardRoutes.vehicles),
                ),
                const SizedBox(height: AppSpacing.medium),
                _FleetStatusRow(
                  label: 'في الصيانة',
                  count: fleet.inMaintenanceVehiclesCount,
                  total: total,
                  color: palette.warning,
                  onTap: () => onOpenModule(DashboardRoutes.vehicles),
                ),
                const Divider(height: AppSpacing.large),
                _RosterStrip(
                  cells: [
                    _RosterCell(
                      icon: DashboardIcons.captain,
                      label: 'السائقون',
                      value: fleet.driversCount,
                      onTap: () => onOpenModule(DashboardRoutes.drivers),
                    ),
                    _RosterCell(
                      icon: DashboardIcons.vehicle,
                      label: 'المركبات',
                      value: total,
                      onTap: () => onOpenModule(DashboardRoutes.vehicles),
                    ),
                    _RosterCell(
                      icon: DashboardIcons.captainRequestsActive,
                      label: 'تعيينات نشطة',
                      value: fleet.activeAssignmentsCount,
                      onTap: () => onOpenModule(DashboardRoutes.fleet),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _FleetStatusRow extends StatelessWidget {
  const _FleetStatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final int total;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : count / total;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(
                '$count',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  // A zero bar is an empty track, which reads as a broken
                  // widget rather than as "none in maintenance"; muting the
                  // figure too makes the whole row say "nothing here".
                  color: count == 0
                      ? DashboardColors.faintInk(context)
                      : DashboardColors.ink(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: text.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'من $total',
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.faintInk(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: DashboardColors.well(context),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The roster totals as one row of three — who the office has, not where they
/// are right now.
class _RosterStrip extends StatelessWidget {
  const _RosterStrip({required this.cells});

  final List<_RosterCell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(child: cells[i]),
          if (i != cells.length - 1)
            Container(
              width: 1,
              height: 26,
              color: DashboardColors.divider(context),
            ),
        ],
      ],
    );
  }
}

class _RosterCell extends StatelessWidget {
  const _RosterCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: DashboardColors.mutedInk(context)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: DashboardColors.mutedInk(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
