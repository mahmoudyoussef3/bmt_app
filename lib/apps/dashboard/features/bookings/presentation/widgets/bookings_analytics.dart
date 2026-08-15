import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/operation_booking.dart';
import 'booking_status_chips.dart';

/// Collapsible analytics block.
///
/// Four charts used to sit *above* the queue, so every visit to the busiest
/// screen in the dashboard began by scrolling past them. They are reporting,
/// not operating: the section lives under the board and starts closed, one tap
/// away for whoever wants it.
///
/// It used to hand-roll that fold with a private `bool _expanded` and its own
/// card header, which made it the one section in the dashboard that forgot the
/// operator's choice the moment the shell rebuilt the module — and gave it a
/// chevron that animated differently from every other section on the screen.
/// [DashboardCollapsibleSection] is the single implementation; the collapsed
/// summary states what the charts cover so a folded section still answers
/// "do I need to open this?".
class BookingsAnalyticsSection extends StatelessWidget {
  const BookingsAnalyticsSection({super.key, required this.bookings});

  final List<OperationBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return DashboardCollapsibleSection(
      sectionId: DashboardSectionIds.bookingsAnalytics,
      icon: Icons.insights_rounded,
      title: 'تحليلات الحجوزات',
      subtitle: 'توزيع الحالات، اتجاه الطلبات، وأكثر المسارات حجزاً',
      initiallyExpanded: false,
      collapsedSummary: DashboardSectionSummary(
        items: ['${bookings.length} حجز', 'حسب الحالة', 'حسب المسار'],
      ),
      child: BookingsAnalytics(bookings: bookings),
    );
  }
}

/// Real-data booking analytics computed from the loaded bookings list:
/// status mix, daily trend, top routes and paid-vs-pending breakdown.
class BookingsAnalytics extends StatelessWidget {
  final List<OperationBooking> bookings;

  const BookingsAnalytics({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);

    final status = DashboardPanel(
      sectionId: DashboardSectionIds.bookingsStatusMix,
      icon: Icons.donut_large_rounded,
      title: 'الحجوزات حسب الحالة',
      subtitle: 'توزيع الحجوزات على حالات سير العمل',
      child: DashboardDonutChart(data: _statusData(context)),
    );
    final payment = DashboardPanel(
      sectionId: DashboardSectionIds.bookingsPaymentMix,
      icon: Icons.pie_chart_outline_rounded,
      title: 'مدفوع مقابل قيد التحصيل',
      subtitle: 'الحجوزات حسب حالة الدفع',
      child: DashboardDonutChart(data: _paymentData(palette)),
    );
    final trend = DashboardPanel(
      sectionId: DashboardSectionIds.bookingsDailyTrend,
      icon: Icons.show_chart_rounded,
      title: 'اتجاه الحجوزات اليومي',
      subtitle: 'عدد الحجوزات حسب اليوم',
      child: DashboardLineChart(
        data: _trendData(palette),
        lineColor: scheme.primary,
      ),
    );
    final routes = DashboardPanel(
      sectionId: DashboardSectionIds.bookingsTopRoutes,
      icon: Icons.leaderboard_rounded,
      title: 'أكثر المسارات حجزاً',
      subtitle: 'أعلى ٦ مسارات حسب عدد الحجوزات',
      child: DashboardRankedBars(data: _routeData(palette)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              status,
              const SizedBox(height: AppSpacing.medium),
              payment,
              const SizedBox(height: AppSpacing.medium),
              trend,
              const SizedBox(height: AppSpacing.medium),
              routes,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: status),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: payment),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: trend),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: routes),
              ],
            ),
          ],
        );
      },
    );
  }

  List<ChartDatum> _statusData(BuildContext context) {
    final counts = <BookingStatus, int>{};
    for (final b in bookings) {
      counts[b.status] = (counts[b.status] ?? 0) + 1;
    }
    return [
      for (final status in BookingStatus.values)
        if ((counts[status] ?? 0) > 0)
          ChartDatum(
            label: status.label,
            value: counts[status]!.toDouble(),

            color: bookingStatusStyle(status).resolve(context).accent,
          ),
    ];
  }

  List<ChartDatum> _paymentData(DashboardChartPalette palette) {
    var paid = 0, pending = 0, cancelled = 0;
    for (final b in bookings) {
      switch (b.paymentStatus) {
        case PaymentStatus.approved:
          paid++;
        case PaymentStatus.failed:
        case PaymentStatus.rejected:
        case PaymentStatus.refunded:
          cancelled++;
        default:
          pending++;
      }
    }
    return [
      ChartDatum(
        label: 'مدفوع',
        value: paid.toDouble(),
        color: palette.positive,
      ),
      ChartDatum(
        label: 'قيد التحصيل',
        value: pending.toDouble(),
        color: palette.warning,
      ),
      ChartDatum(
        label: 'ملغي/مرفوض',
        value: cancelled.toDouble(),
        color: palette.negative,
      ),
    ];
  }

  List<ChartDatum> _trendData(DashboardChartPalette palette) {
    final byDay = <DateTime, int>{};
    for (final b in bookings) {
      final d = DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
      byDay[d] = (byDay[d] ?? 0) + 1;
    }
    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        ChartDatum(
          label: '${day.day}/${day.month}',
          value: byDay[day]!.toDouble(),
          color: palette.active,
        ),
    ];
  }

  List<ChartDatum> _routeData(DashboardChartPalette palette) {
    final counts = <String, int>{};
    for (final b in bookings) {
      final route = b.route.isEmpty ? 'غير محدد' : b.route;
      counts[route] = (counts[route] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final (index, entry) in sorted.take(6).indexed)
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: palette.categoryAt(index),
        ),
    ];
  }
}
