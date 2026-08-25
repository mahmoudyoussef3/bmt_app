import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Which corridors are earning their buses, best first.
///
/// [DashboardHomeSummary.topRoutes] has computed this since the page was
/// built and nothing ever drew it, so the one standing question a home screen
/// can genuinely answer — *where should the next bus go?* — was the one it
/// stayed silent on. The KPI row says how full today was overall; this says
/// which routes made it so, and a route sitting at 30% over a month of trips
/// is a schedule decision the operator can act on this week.
///
/// A month's window and a real denominator: cancelled trips and routes with no
/// seats on offer are excluded upstream, so no corridor appears at 0% because
/// nobody ever put a bus on it.
class RoutePerformanceSection extends StatelessWidget {
  const RoutePerformanceSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
    this.maxRows = 5,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;
  final int maxRows;

  /// Matches the window [DashboardHomeSummary.topRoutes] defaults to, so the
  /// subtitle cannot drift away from what the rows actually cover.
  static const _windowDays = 30;

  @override
  Widget build(BuildContext context) {
    final routes = summary.topRoutes(limit: maxRows, windowDays: _windowDays);

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeRoutePerformance,
      icon: DashboardIcons.routesActive,
      title: 'أداء المسارات',
      subtitle: routes.isEmpty
          ? null
          : 'نسبة إشغال المقاعد خلال آخر $_windowDays يوماً',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.routes),
        child: const Text('كل المسارات'),
      ),
      child: routes.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.routes,
              title: 'لا بيانات إشغال بعد',
              message: 'تظهر النسب بعد تشغيل أول رحلة على مسار.',
            )
          : Column(
              children: [
                for (var i = 0; i < routes.length; i++) ...[
                  _RouteRow(
                    rank: i + 1,
                    occupancy: routes[i],
                    onOpen: () => onOpenModule(DashboardRoutes.trips),
                  ),
                  if (i != routes.length - 1)
                    const SizedBox(height: AppSpacing.medium),
                ],
              ],
            ),
    );
  }
}

/// One corridor: its standing, its name, how many trips it carried, and a
/// track showing how full they ran.
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.rank,
    required this.occupancy,
    required this.onOpen,
  });

  final int rank;
  final RouteOccupancy occupancy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);
    final rate = occupancy.occupancyRate;
    final percent = (rate * 100).round();
    final radius = BorderRadius.circular(8);

    // Three bands, not a gradient: an operator reads "is this route healthy"
    // as a yes/watch/no, and a continuous ramp makes 61% and 69% look like
    // different answers when they are the same one.
    final tone = rate >= 0.7
        ? palette.positive
        : rate >= 0.4
        ? palette.warning
        : palette.negative;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$rank',
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.faintInk(context),
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      occupancy.route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    '$percent%',
                    style: text.titleSmall?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: rate.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: DashboardColors.well(context),
                          valueColor: AlwaysStoppedAnimation(tone),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      '${occupancy.bookedSeats}/${occupancy.capacity} مقعد'
                      ' · ${occupancy.trips} رحلة',
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
