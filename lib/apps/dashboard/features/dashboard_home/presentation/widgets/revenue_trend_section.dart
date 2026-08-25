import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The office's money, in the two readings that answer different questions.
///
/// **What the office has taken** — today, this week, this month — straight from
/// [RevenueMetrics], the Finance module's own figures, so the three numbers here
/// are the three numbers there. They cover every source of income the office
/// has, bookings and subscriptions alike.
///
/// **Whether it is speeding up or slowing down** — the daily line underneath.
/// That series counts *bookings only*, and only once their payment reached
/// [PaymentStatus.approved], dated by when the booking was taken: the same two
/// rules Finance uses for realised revenue. Subscription income is not in the
/// list this screen loads, so folding it in would mean guessing — which is why
/// the two halves are captioned separately rather than presented as one number
/// with a chart under it. A reader who takes the last point of the line for
/// "today's revenue" would be reading a different, smaller measure, and the
/// caption is what stops them.
///
/// A fixed 14-day window, no toggle: this card lives in Home's narrow side
/// rail, and a period-switcher wide enough to tap comfortably does not fit that
/// column. The full, window-adjustable read of this same series lives one click
/// away in Finance.
///
/// The series is drawn as a line rather than the bar chart it used to be. In a
/// rail this narrow fourteen bars became fourteen slivers with a value printed
/// over each one, and a quiet stretch — which is most windows, since a bar for
/// a zero day is nothing at all — read as a broken chart rather than a flat
/// week. A line keeps its shape through the zeros.
class RevenueTrendSection extends StatelessWidget {
  const RevenueTrendSection({super.key, required this.summary});

  final DashboardHomeSummary summary;

  static const _days = 14;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final revenue = summary.revenue;
    final series = summary.bookingRevenueSeries(days: _days);
    final total = series.fold<double>(0, (sum, point) => sum + point.amount);
    final paidBookings = series.fold<int>(
      0,
      (sum, point) => sum + point.bookings,
    );

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeRevenueTrend,
      icon: DashboardIcons.trend,
      title: 'الإيرادات',
      subtitle: 'إجمالي محصّل من الحجوزات والاشتراكات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoneyStrip(
            cells: [
              _MoneyCell(label: 'اليوم', amount: revenue.todayRevenue),
              _MoneyCell(label: 'الأسبوع', amount: revenue.weeklyRevenue),
              _MoneyCell(label: 'الشهر', amount: revenue.monthlyRevenue),
            ],
          ),
          const Divider(height: AppSpacing.large),
          Text(
            'إيراد الحجوزات المحصّل',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            total <= 0
                ? 'آخر $_days يوماً · المدفوعات المقبولة فقط'
                : 'إجمالي ${total.toStringAsFixed(0)} ج.م من $paidBookings حجز خلال آخر $_days يوماً',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
          if (total <= 0)
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
                data: [
                  for (final point in series)
                    ChartDatum(
                      label: _dayLabel(point.day, point == series.last),
                      value: point.amount,
                      color: palette.positive,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// `d/M`, or "اليوم" for the series' last point — short enough that the axis
  /// stays legible, and today's end of the line reads without counting.
  String _dayLabel(DateTime day, bool isToday) =>
      isToday ? 'اليوم' : '${day.day}/${day.month}';
}

/// The three period totals side by side. A row, not three stacked rows: they
/// are the same measure over widening windows and an operator compares them
/// left to right, so stacking them would turn one reading into three.
class _MoneyStrip extends StatelessWidget {
  const _MoneyStrip({required this.cells});

  final List<_MoneyCell> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(child: cells[i]),
          if (i != cells.length - 1)
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
              color: DashboardColors.divider(context),
            ),
        ],
      ],
    );
  }
}

class _MoneyCell extends StatelessWidget {
  const _MoneyCell({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${amount.toStringAsFixed(0)} ج.م',
            maxLines: 1,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
