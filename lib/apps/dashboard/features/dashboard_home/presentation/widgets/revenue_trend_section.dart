import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
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
class RevenueTrendSection extends StatefulWidget {
  const RevenueTrendSection({super.key, required this.summary});

  final DashboardHomeSummary summary;

  @override
  State<RevenueTrendSection> createState() => _RevenueTrendSectionState();
}

class _RevenueTrendSectionState extends State<RevenueTrendSection> {
  static const _windows = <int, String>{
    7: '٧ أيام',
    30: '٣٠ يوم',
    90: '٣ شهور',
  };

  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final series = widget.summary.bookingRevenueSeries(days: _days);
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
          ? 'المدفوعات المقبولة فقط'
          : 'إجمالي ${total.toStringAsFixed(0)} ج.م من $paidBookings حجز مدفوع',
      trailing: SegmentedButton<int>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: [
          for (final entry in _windows.entries)
            ButtonSegment<int>(value: entry.key, label: Text(entry.value)),
        ],
        selected: {_days},
        onSelectionChanged: (selection) =>
            setState(() => _days = selection.first),
      ),
      child: total <= 0
          ? const DashboardEmptyState(
              icon: DashboardIcons.revenue,
              title: 'لا مدفوعات محصّلة في هذه الفترة',
              message: 'يظهر الرسم فور اعتماد أول دفعة.',
            )
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.small),
              child: DashboardLineChart(
                lineColor: palette.positive,
                data: [
                  for (final point in series)
                    ChartDatum(
                      label: _dayLabel(point.day),
                      value: point.amount,
                      color: scheme.primary,
                    ),
                ],
              ),
            ),
    );
  }

  /// `d/M` — short enough that a 90-day axis stays legible; the chart only
  /// renders every fourth label anyway.
  String _dayLabel(DateTime day) => '${day.day}/${day.month}';
}
