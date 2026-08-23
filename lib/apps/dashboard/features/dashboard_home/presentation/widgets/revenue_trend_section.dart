import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_bar_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// One chart, one question: is money coming in faster or slower than it was?
///
/// Plots **collected booking revenue per day** — approved payments only, dated
/// by when the booking was taken, which is the same rule the Finance module
/// uses for realised revenue. Subscription income is not in the list this
/// screen loads, so it is honestly excluded and the panel says so rather than
/// implying a total it cannot compute.
///
/// A fixed 14-day window, no toggle: this card lives in Home's narrow side
/// rail next to the fleet strip, not as a full-width panel, and a
/// period-switcher wide enough to tap comfortably does not fit that column.
/// The full, window-adjustable read of this same series lives one click away
/// in Finance.
class RevenueTrendSection extends StatelessWidget {
  const RevenueTrendSection({super.key, required this.summary});

  final DashboardHomeSummary summary;

  static const _days = 14;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final series = summary.bookingRevenueSeries(days: _days);
    final total = series.fold<double>(0, (sum, point) => sum + point.amount);
    final paidBookings = series.fold<int>(
      0,
      (sum, point) => sum + point.bookings,
    );

    return DashboardPanel(
      sectionId: DashboardSectionIds.homeRevenueTrend,
      icon: DashboardIcons.trend,
      title: 'إيراد الحجوزات المحصّل',
      subtitle: total <= 0
          ? 'آخر $_days يوماً · المدفوعات المقبولة فقط'
          : 'إجمالي ${total.toStringAsFixed(0)} ج.م من $paidBookings حجز خلال آخر $_days يوماً',
      child: total <= 0
          ? const DashboardEmptyState(
              icon: DashboardIcons.revenue,
              title: 'لا مدفوعات محصّلة في هذه الفترة',
              message: 'يظهر الرسم فور اعتماد أول دفعة.',
            )
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: DashboardBarChart(
                data: [
                  for (final point in series)
                    ChartDatum(
                      label: _dayLabel(point.day, point == series.last),
                      value: point.amount,
                      // Today's bar carries the accent; the rest of the
                      // window is a muted reference so "how are we doing
                      // right now" reads at a glance without a legend.
                      color: point == series.last
                          ? scheme.primary
                          : palette.neutral,
                    ),
                ],
              ),
            ),
    );
  }

  /// `d/M`, or "اليوم" for the series' last point — short enough that a
  /// 90-day axis stays legible, and today's bar reads without counting.
  String _dayLabel(DateTime day, bool isToday) =>
      isToday ? 'اليوم' : '${day.day}/${day.month}';
}
