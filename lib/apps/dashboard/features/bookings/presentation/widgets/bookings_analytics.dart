import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
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
/// not operating: the section now lives under the board and starts closed, one
/// tap away for whoever wants it.
class BookingsAnalyticsSection extends StatefulWidget {
  const BookingsAnalyticsSection({super.key, required this.bookings});

  final List<OperationBooking> bookings;

  @override
  State<BookingsAnalyticsSection> createState() =>
      _BookingsAnalyticsSectionState();
}

class _BookingsAnalyticsSectionState extends State<BookingsAnalyticsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () => setState(() => _expanded = !_expanded),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Icon(Icons.insights_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليلات الحجوزات',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'توزيع الحالات، اتجاه الطلبات، وأكثر المسارات حجزاً',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppTokens.motionBase,
                child: const Icon(Icons.expand_more_rounded),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.medium),
          BookingsAnalytics(bookings: widget.bookings),
        ],
      ],
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

    final status = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'الحجوزات حسب الحالة',
      subtitle: 'توزيع الحجوزات على حالات سير العمل',
      child: DashboardDonutChart(data: _statusData()),
    );
    final payment = DashboardPanel(
      icon: Icons.pie_chart_outline_rounded,
      title: 'مدفوع مقابل قيد التحصيل',
      subtitle: 'الحجوزات حسب حالة الدفع',
      child: DashboardDonutChart(data: _paymentData()),
    );
    final trend = DashboardPanel(
      icon: Icons.show_chart_rounded,
      title: 'اتجاه الحجوزات اليومي',
      subtitle: 'عدد الحجوزات حسب اليوم',
      child: DashboardLineChart(data: _trendData(), lineColor: scheme.primary),
    );
    final routes = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'أكثر المسارات حجزاً',
      subtitle: 'أعلى ٦ مسارات حسب عدد الحجوزات',
      child: DashboardRankedBars(data: _routeData(scheme)),
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

  List<ChartDatum> _statusData() {
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
            // Same colour the status wears on every chip and KPI tile, instead
            // of a second private palette that disagreed with them.
            color: bookingStatusStyle(status).onContainer,
          ),
    ];
  }

  List<ChartDatum> _paymentData() {
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
        color: DashboardChartPalette.positive,
      ),
      ChartDatum(
        label: 'قيد التحصيل',
        value: pending.toDouble(),
        color: DashboardChartPalette.warning,
      ),
      ChartDatum(
        label: 'ملغي/مرفوض',
        value: cancelled.toDouble(),
        color: DashboardChartPalette.negative,
      ),
    ];
  }

  List<ChartDatum> _trendData() {
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
          color: DashboardChartPalette.active,
        ),
    ];
  }

  List<ChartDatum> _routeData(ColorScheme scheme) {
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
          color: DashboardChartPalette.categoryAt(index),
        ),
    ];
  }
}
