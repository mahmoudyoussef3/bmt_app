import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';
import 'overview_kit.dart';

/// Today's operations, summarised — and deliberately **not** scoped to the
/// page's period.
///
/// Trips running now, drivers rostered, buses on the road and open incidents
/// are facts about this minute. Re-scoping them to «آخر ٩٠ يوماً» would not
/// make them more informative, it would make them meaningless, so the panel
/// says «اليوم» in its subtitle and stays there while the rest of the page
/// moves. That split — live state here, measured periods everywhere else — is
/// the thing the previous revision left implicit.
///
/// Operations and Live Ops own the work itself: the trip rows, the seat maps,
/// the tracking health, the incident queue. Restating any of that here would
/// give an owner a second place to manage from and a second place for it to be
/// out of date.
///
/// The delay figure is derived from the schedule, not from live tracking, so it
/// reads the same whether or not the office is licensed for Live Ops.
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
    final delayed = overview.delayedTrips.length;
    final unassigned = overview.tripsWithoutCaptain.length;
    final hasLiveOps = overview.has(BusinessDataSource.liveOps);
    final hasFleet = overview.has(BusinessDataSource.fleet);
    final scheduled = overview.todayTrips.length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessOperational,
      icon: DashboardIcons.operations,
      title: 'الأداء التشغيلي',
      subtitle: 'اليوم — أرقام لحظية لا تتبع الفترة المختارة',
      trailing: OverviewPanelAction(
        label: 'العمليات المباشرة',
        onPressed: () => onOpenModule(DashboardRoutes.liveOps),
      ),
      collapsedSummary: Text(
        '${count(overview.tripsRunningNow)} جارية · '
        '${count(overview.tripsUpcomingToday)} قادمة · '
        '${count(delayed)} متأخرة',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scheduled == 0)
            const DashboardEmptyState(
              icon: DashboardIcons.trips,
              title: 'لا رحلات مجدولة اليوم',
              message:
                  'لم تُجدول أي رحلة على تاريخ اليوم. تظهر حالة التشغيل هنا '
                  'فور جدولة أول رحلة.',
            )
          else ...[
            _TripPipeline(overview: overview, onOpenModule: onOpenModule),
            const Divider(height: AppSpacing.large),
          ],
          OverviewTrackRow(
            label: 'استغلال الأسطول',
            ratio: overview.fleetUtilisation,
            tone: (overview.fleetUtilisation ?? 0) >= 0.6
                ? palette.positive
                : palette.active,
            trailingNote: hasFleet
                ? 'من ${count(overview.activeVehicles)}'
                : null,
            notes: [
              '${count(overview.vehiclesOnRoad)} مركبة على الطريق',
              if (hasFleet)
                '${count(overview.vehiclesInMaintenance)} في الصيانة',
            ],
            emptyNote: hasFleet
                ? 'لا توجد مركبات نشطة لقياس الاستغلال عليها.'
                : 'تعذّر تحميل الأسطول، فلا يمكن قياس الاستغلال.',
            onTap: () => onOpenModule(DashboardRoutes.vehicles),
          ),
          const Divider(height: AppSpacing.large),
          OverviewCellStrip(
            cells: [
              OverviewCell(
                icon: DashboardIcons.time,
                label: 'رحلات متأخرة',
                value: count(delayed),
                note: 'فات موعد القيام',
                tone: delayed > 0 ? palette.negative : null,
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
              OverviewCell(
                icon: DashboardIcons.captain,
                label: 'بدون سائق',
                value: count(unassigned),
                note: 'تحتاج تعييناً',
                tone: unassigned > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.trips),
              ),
              OverviewCell(
                icon: DashboardIcons.captains,
                label: 'سائقون في الخدمة',
                value: count(overview.driversOnDuty),
                note: hasFleet
                    ? 'من ${count(overview.activeDrivers)} نشطاً'
                    : 'على رحلات اليوم',
                onTap: () => onOpenModule(DashboardRoutes.drivers),
              ),
              OverviewCell(
                icon: DashboardIcons.incident,
                label: 'بلاغات مفتوحة',
                value: hasLiveOps ? count(overview.openIncidents) : '—',
                note: hasLiveOps ? 'من الكباتن' : 'تعذّر تحميل العمليات',
                tone: overview.openIncidents > 0 ? palette.warning : null,
                onTap: () => onOpenModule(DashboardRoutes.liveOps),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Today's schedule as one bar: what has run, what is running, what is still to
/// come, and what was called off.
///
/// Four counts used to be four bordered tiles in a grid, which made them look
/// like four unrelated measurements. They are one measurement — the day — split
/// four ways, and a stacked bar is the shape that says so. It also answers the
/// question the tiles could not: *how far through the day are we*.
class _TripPipeline extends StatelessWidget {
  const _TripPipeline({required this.overview, required this.onOpenModule});

  final BusinessOverview overview;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);

    final segments = <_Segment>[
      _Segment(
        label: 'مكتملة',
        value: overview.tripsCompletedToday,
        color: palette.positive,
      ),
      _Segment(
        label: 'جارية الآن',
        value: overview.tripsRunningNow,
        color: palette.active,
      ),
      _Segment(
        label: 'قادمة',
        value: overview.tripsUpcomingToday,
        color: palette.neutral,
      ),
      _Segment(
        label: 'ملغاة',
        value: overview.tripsCancelledToday,
        color: palette.negative,
      ),
    ];
    final drawn = segments.where((s) => s.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'رحلات اليوم',
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${count(overview.todayTrips.length)} رحلة مجدولة',
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: drawn.isEmpty
                ? ColoredBox(color: DashboardColors.well(context))
                : Row(
                    // Stretch, not the default centre: an `Expanded`
                    // `ColoredBox` gets loose vertical constraints under
                    // `CrossAxisAlignment.center` and paints nothing at all —
                    // the bar was a band of empty space.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final segment in drawn)
                        Expanded(
                          flex: segment.value,
                          child: Tooltip(
                            message: '${segment.label} ${count(segment.value)}',
                            child: ColoredBox(color: segment.color),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.xSmall,
          children: [
            for (final segment in segments)
              _LegendEntry(
                segment: segment,
                onTap: () => onOpenModule(
                  segment.label == 'جارية الآن'
                      ? DashboardRoutes.liveOps
                      : DashboardRoutes.trips,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.segment, required this.onTap});

  final _Segment segment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: segment.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${segment.label} ${count(segment.value)}',
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: DashboardColors.mutedInk(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
