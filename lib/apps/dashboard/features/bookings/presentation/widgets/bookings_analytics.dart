import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/operation_booking.dart';

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
            color: _statusColor(status),
          ),
    ];
  }

  List<ChartDatum> _paymentData() {
    var paid = 0, pending = 0, cancelled = 0;
    for (final b in bookings) {
      switch (b.status) {
        case BookingStatus.approved:
        case BookingStatus.confirmed:
          paid++;
        case BookingStatus.cancelled:
        case BookingStatus.rejected:
          cancelled++;
        default:
          pending++;
      }
    }
    return [
      ChartDatum(label: 'مدفوع', value: paid.toDouble(), color: const Color(0xFF16A34A)),
      ChartDatum(label: 'قيد التحصيل', value: pending.toDouble(), color: const Color(0xFFF59E0B)),
      ChartDatum(label: 'ملغي/مرفوض', value: cancelled.toDouble(), color: const Color(0xFFDC2626)),
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
          color: const Color(0xFF2563EB),
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
      for (final entry in sorted.take(6))
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: scheme.primary,
        ),
    ];
  }

  Color _statusColor(BookingStatus status) => switch (status) {
        BookingStatus.newRequest => const Color(0xFF06B6D4),
        BookingStatus.paymentUploaded => const Color(0xFF0EA5E9),
        BookingStatus.underReview => const Color(0xFFF59E0B),
        BookingStatus.approved => const Color(0xFF22C55E),
        BookingStatus.confirmed => const Color(0xFF16A34A),
        BookingStatus.requestReupload => const Color(0xFFA855F7),
        BookingStatus.rejected => const Color(0xFFDC2626),
        BookingStatus.cancelled => const Color(0xFF64748B),
      };
}
