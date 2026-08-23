import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Standing capacity: what the office has to run trips with today, read as a
/// single dimension — each vehicle's operational status — rather than four
/// unrelated tallies. [FleetSummary.inServiceVehiclesCount] /
/// `unassignedVehiclesCount` / `inMaintenanceVehiclesCount` already partition
/// every non-archived vehicle exactly once (see `FleetWorkspace.summary`), so
/// the three bars below always add up to the fleet total.
///
/// Anything here that needs a *decision* (expiring documents, join requests)
/// is raised by the attention panel instead; this is inventory, not a queue.
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
      title: 'حالة الأسطول',
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
              width: 72,
              child: Text(
                '$count',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: DashboardColors.divider(context),
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
