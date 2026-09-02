import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/business_metric.dart';
import '../../domain/entities/business_overview.dart';
import '../models/overview_window.dart';
import 'overview_format.dart';
import 'overview_kit.dart';

/// Whether the money is speeding up or slowing down — the daily series, drawn
/// once and properly, in الرئيسية's own revenue panel shape.
///
/// It reads the *page's* window rather than Home's fixed fourteen days, which
/// is the one thing that differs: Home's card lives in a narrow rail where a
/// period switcher would not fit, and this page has one switcher governing
/// every panel at once.
///
/// The three totals above the chart are windows of the same measure widening
/// left to right — today, the period, and what is still owed — so an owner can
/// place the chart's last point against the period behind it without doing the
/// arithmetic.
///
/// A line rather than bars: a bar for a zero day is nothing at all, so a quiet
/// stretch reads as a broken chart. A line keeps its shape through the zeros.
class RevenueTrendSection extends StatelessWidget {
  const RevenueTrendSection({
    super.key,
    required this.overview,
    required this.window,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final series = overview.revenueSeries(days: window.days);
    final collected = overview.collected(days: window.days);
    final activeDays = series.where((point) => point.value > 0).length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessRevenueTrend,
      icon: DashboardIcons.trend,
      title: 'اتجاه التحصيل',
      subtitle: 'إيراد الحجوزات المحصّل يوماً بيوم',
      trailing: OverviewPanelAction(
        label: 'المدفوعات',
        onPressed: () => onOpenModule(DashboardRoutes.payments),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OverviewCellStrip(
            cells: [
              OverviewCell(
                icon: DashboardIcons.time,
                label: 'اليوم',
                value: money(overview.revenueToday),
              ),
              OverviewCell(
                icon: DashboardIcons.revenue,
                label: window.label,
                value: money(collected),
              ),
              OverviewCell(
                icon: DashboardIcons.paymentReview,
                label: 'مستحق الآن',
                value: money(overview.outstanding),
                tone: overview.outstanding > 0 ? palette.warning : null,
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),
          Text(
            'التحصيل اليومي',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            activeDays == 0
                ? '${window.title} · المدفوعات المقبولة فقط'
                : '${count(activeDays)} يوم فيه تحصيل خلال ${window.title}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          if (activeDays == 0)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.small),
              child: DashboardEmptyState(
                icon: DashboardIcons.revenue,
                title: 'لا مدفوعات محصّلة في هذه الفترة',
                message: 'يظهر الرسم فور اعتماد أول دفعة.',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: DashboardLineChart(
                lineColor: palette.positive,
                tooltipFormatter: money,
                averageLabel: 'متوسط اليوم',
                data: [
                  for (final point in series)
                    ChartDatum(
                      label: _dayLabel(point, isLast: point == series.last),
                      value: point.value,
                      color: palette.positive,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// `d/M`, or «اليوم» for the series' last point — the same axis label Home
  /// draws, so today's end of the line reads without counting.
  String _dayLabel(DailyMetric point, {required bool isLast}) =>
      isLast ? 'اليوم' : '${point.day.day}/${point.day.month}';
}
