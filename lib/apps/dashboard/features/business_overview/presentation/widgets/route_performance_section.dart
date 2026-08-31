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
import '../models/overview_window.dart';
import 'overview_format.dart';
import 'overview_kit.dart';

/// Which corridors are earning their buses, best first.
///
/// **This panel is not new data — it is data that was already being computed
/// and thrown away.** `BusinessOverview.routeStandings` existed, was tested,
/// and was read by exactly one thing: a sentence in «قراءات وتوصيات» naming the
/// best and worst route. An owner who wanted the ranking had to open Reports.
///
/// Occupancy is the ranking key rather than revenue because this page already
/// has three places that say how much money came in and none that says where
/// the *capacity* went. A route running at 40% is a decision — fewer buses, a
/// different time, a lower fare — and it is invisible in a revenue ranking,
/// where a busy corridor at 40% still outranks a small one at 95%.
///
/// The row is الرئيسية's route row exactly: a rank in a narrow lane, the name,
/// the percentage, then the track with its denominator beside it. Home answers
/// the same question on its own page and the two rankings should not be two
/// different objects.
class RoutePerformanceSection extends StatelessWidget {
  const RoutePerformanceSection({
    super.key,
    required this.overview,
    required this.window,
    required this.onOpenModule,
    this.maxRows = 5,
  });

  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<String> onOpenModule;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final standings = overview.routeStandings(
      limit: maxRows,
      windowDays: window.days,
    );
    final best = standings.isEmpty ? null : standings.first;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessRoutes,
      icon: DashboardIcons.routesActive,
      title: 'أداء المسارات',
      subtitle: standings.isEmpty
          ? null
          : 'نسبة إشغال المقاعد خلال ${window.title}',
      trailing: OverviewPanelAction(
        label: 'كل المسارات',
        onPressed: () => onOpenModule(DashboardRoutes.routes),
      ),
      collapsedSummary: Text(
        best == null
            ? 'لا رحلات مُجدولة في الفترة'
            : 'الأعلى إشغالاً ${best.route} · ${percent(best.occupancyRate)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
      child: standings.isEmpty
          ? DashboardEmptyState(
              icon: DashboardIcons.routes,
              title: 'لا بيانات إشغال بعد',
              message:
                  'لم تُشغَّل رحلات بمقاعد معروضة خلال ${window.title}. '
                  'تظهر النسب بعد تشغيل أول رحلة على مسار.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < standings.length; i++) ...[
                  _RouteRow(
                    rank: i + 1,
                    standing: standings[i],
                    onOpen: () => onOpenModule(DashboardRoutes.trips),
                  ),
                  if (i != standings.length - 1)
                    const SizedBox(height: AppSpacing.medium),
                ],
                const SizedBox(height: AppSpacing.small),
                Text(
                  'الرحلات الملغاة والرحلات بلا مقاعد معروضة مستبعدة — أولاهما '
                  'لم تكن ستمتلئ، والثانية تظهر كخط بنسبة صفر لم يوجد أصلاً.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DashboardColors.faintInk(context),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One corridor: its standing, its name, how full its buses ran, and what that
/// was out of.
///
/// The bar and the fraction say the same thing on purpose. The bar is what the
/// eye ranks by in one pass; the fraction is what an owner needs before acting
/// on it, because 100% of four seats and 100% of two hundred are not the same
/// finding.
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.rank,
    required this.standing,
    required this.onOpen,
  });

  final int rank;
  final RouteStanding standing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);
    final rate = standing.occupancyRate;
    final radius = BorderRadius.circular(8);

    // Three bands, not a gradient: an operator reads "is this route healthy" as
    // a yes/watch/no, and a continuous ramp makes 61% and 69% look like
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
                      standing.route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    percent(rate),
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
                      '${count(standing.bookedSeats)}/'
                      '${count(standing.capacity)} مقعد'
                      ' · ${count(standing.trips)} رحلة',
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
