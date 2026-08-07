import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';
import 'overview_metric.dart';

/// Section 5 — today's operations, summarised.
///
/// A count and a way in, nothing more. Operations and Live Ops own the work
/// itself: the trip rows, the seat maps, the tracking health, the incident
/// queue. Restating any of that here would give an owner a second place to
/// manage from and a second place for it to be out of date.
///
/// The delay figure is derived from the schedule, not from live tracking, so
/// it reads the same whether or not the office is licensed for Live Ops.
class OperationalSnapshotSection extends StatelessWidget {
  const OperationalSnapshotSection({
    super.key,
    required this.overview,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final delayed = overview.delayedTrips.length;
    final hasLiveOps = overview.has(BusinessDataSource.liveOps);

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessOperational,
      icon: DashboardIcons.operations,
      title: 'الملخص التشغيلي',
      subtitle: 'حالة اليوم · الإدارة الكاملة في وحدتَي الرحلات والعمليات',
      trailing: TextButton.icon(
        onPressed: () => onOpenModule(DashboardRoutes.liveOps),
        icon: const Icon(DashboardIcons.openModule, size: 16),
        label: const Text('العمليات المباشرة'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
      collapsedSummary: Text(
        '${count(overview.tripsRunningNow)} جارية · '
        '${count(overview.tripsUpcomingToday)} قادمة · '
        '$delayed متأخرة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverviewMetricGrid(
            children: [
              OverviewMetric(
                label: 'رحلات جارية الآن',
                value: count(overview.tripsRunningNow),
                hint: 'على الطريق',
                tone: overview.tripsRunningNow > 0 ? palette.active : null,
                onTap: () => onOpenModule(DashboardRoutes.liveOps),
              ),
              OverviewMetric(
                label: 'رحلات قادمة اليوم',
                value: count(overview.tripsUpcomingToday),
                hint: 'لم يحن موعدها بعد',
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
              OverviewMetric(
                label: 'رحلات متأخرة',
                value: count(delayed),
                hint: 'فات موعد القيام ولم تبدأ',
                tone: delayed > 0 ? palette.negative : null,
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
              OverviewMetric(
                label: 'رحلات مكتملة اليوم',
                value: count(overview.tripsCompletedToday),
                hint: 'من ${count(overview.tripsToday)} رحلة',
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
              OverviewMetric(
                label: 'سائقون في الخدمة',
                value: count(overview.driversOnDuty),
                hint: 'من ${count(overview.activeDrivers)} سائقاً نشطاً',
                onTap: () => onOpenModule(DashboardRoutes.drivers),
              ),
              OverviewMetric(
                label: 'مركبات على الطريق',
                value: count(overview.vehiclesOnRoad),
                hint: '${count(overview.vehiclesInMaintenance)} في الصيانة',
                onTap: () => onOpenModule(DashboardRoutes.vehicles),
              ),
              OverviewMetric(
                label: 'بلاغات مفتوحة',
                value: hasLiveOps ? count(overview.openIncidents) : '—',
                hint: hasLiveOps
                    ? 'من بلاغات الكباتن'
                    : 'تعذّر تحميل العمليات المباشرة',
                tone: overview.openIncidents > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.liveOps),
              ),
              OverviewMetric(
                label: 'رحلات ملغاة اليوم',
                value: count(overview.tripsCancelledToday),
                hint: 'خارج الطاقة التشغيلية',
                tone: overview.tripsCancelledToday > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _NavButton(
                icon: DashboardIcons.trips,
                label: 'الرحلات',
                onPressed: () => onOpenModule(DashboardRoutes.trips),
              ),
              _NavButton(
                icon: DashboardIcons.liveOps,
                label: 'العمليات المباشرة',
                onPressed: () => onOpenModule(DashboardRoutes.liveOps),
              ),
              _NavButton(
                icon: DashboardIcons.fleet,
                label: 'إدارة الأسطول',
                onPressed: () => onOpenModule(DashboardRoutes.fleet),
              ),
              _NavButton(
                icon: DashboardIcons.routes,
                label: 'المسارات',
                onPressed: () => onOpenModule(DashboardRoutes.routes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}
