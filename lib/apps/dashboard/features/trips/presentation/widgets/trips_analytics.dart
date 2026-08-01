import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_bar_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

/// Real-data analytics for the trips workspace — everything below is computed
/// from the already-loaded trips list (no extra fetch, no mock data).
class TripsAnalytics extends StatelessWidget {
  final TripsListLoaded state;

  const TripsAnalytics({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final donut = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'توزيع حالات الرحلات',
      subtitle: 'كل الرحلات حسب الحالة التشغيلية',
      child: DashboardDonutChart(data: _statusData(context)),
    );
    final bars = DashboardPanel(
      icon: Icons.bar_chart_rounded,
      title: 'إشغال الرحلات',
      subtitle: 'عدد الرحلات حسب نسبة الإشغال',
      child: DashboardBarChart(data: _occupancyData(palette)),
    );
    final routes = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'أكثر المسارات تشغيلاً',
      subtitle: 'أعلى ٥ مسارات بعدد الرحلات',
      child: DashboardRankedBars(data: _topRoutes(palette)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              donut,
              const SizedBox(height: AppSpacing.medium),
              bars,
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
                Expanded(child: donut),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: bars),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            routes,
          ],
        );
      },
    );
  }

  List<ChartDatum> _statusData(BuildContext context) {
    final counts = <OperationTripStatus, int>{};
    for (final trip in state.trips) {
      counts[trip.status] = (counts[trip.status] ?? 0) + 1;
    }
    return [
      for (final status in OperationTripStatus.values)
        if ((counts[status] ?? 0) > 0)
          ChartDatum(
            label: status.label,
            value: counts[status]!.toDouble(),
            color: _statusColor(context, status),
          ),
    ];
  }

  List<ChartDatum> _occupancyData(DashboardChartPalette palette) {
    var empty = 0, low = 0, mid = 0, high = 0, full = 0;
    for (final trip in state.trips) {
      if (trip.capacity == 0) continue;
      final ratio = trip.bookedSeats / trip.capacity;
      if (trip.bookedSeats == 0) {
        empty++;
      } else if (trip.availableSeats == 0) {
        full++;
      } else if (ratio < 0.5) {
        low++;
      } else if (ratio < 0.8) {
        mid++;
      } else {
        high++;
      }
    }
    // Empty seats are the revenue problem, so an empty trip reads as negative
    // and a full one as positive — the same direction the palette uses everywhere.
    return [
      ChartDatum(
        label: 'فارغة',
        value: empty.toDouble(),
        color: palette.negative,
      ),
      ChartDatum(label: 'منخفض', value: low.toDouble(), color: palette.warning),
      ChartDatum(label: 'متوسط', value: mid.toDouble(), color: palette.accent),
      ChartDatum(label: 'مرتفع', value: high.toDouble(), color: palette.active),
      ChartDatum(
        label: 'ممتلئة',
        value: full.toDouble(),
        color: palette.positive,
      ),
    ];
  }

  List<ChartDatum> _topRoutes(DashboardChartPalette palette) {
    final counts = <String, int>{};
    for (final trip in state.trips) {
      counts[trip.route] = (counts[trip.route] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final (index, entry) in sorted.take(5).indexed)
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: palette.categoryAt(index),
        ),
    ];
  }
}

Color _statusColor(BuildContext context, OperationTripStatus status) {
  final palette = DashboardChartPalette.of(context);
  return switch (status) {
    OperationTripStatus.scheduled => palette.neutral,
    OperationTripStatus.openForBooking => palette.active,
    OperationTripStatus.boarding => palette.warning,
    OperationTripStatus.inProgress => palette.accent,
    OperationTripStatus.completed => palette.positive,
    OperationTripStatus.cancelled => palette.negative,
  };
}
