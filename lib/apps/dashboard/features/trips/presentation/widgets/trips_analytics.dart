import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_bar_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

import 'trip_ui_helpers.dart';

/// Real-data analytics for the trips workspace — everything below is computed
/// from the already-loaded trips list (no extra fetch, no mock data).
class TripsAnalytics extends StatelessWidget {
  final TripsListLoaded state;

  const TripsAnalytics({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final donut = DashboardPanel(
      sectionId: DashboardSectionIds.tripsStatusMix,
      icon: Icons.donut_large_rounded,
      title: 'توزيع حالات الرحلات',
      subtitle: 'كل الرحلات حسب الحالة التشغيلية',
      child: DashboardDonutChart(data: _statusData(context)),
    );
    final bars = DashboardPanel(
      sectionId: DashboardSectionIds.tripsOccupancy,
      icon: Icons.bar_chart_rounded,
      title: 'إشغال الرحلات',
      subtitle: 'عدد الرحلات حسب نسبة الإشغال',
      child: DashboardBarChart(data: _occupancyData(palette)),
    );
    final routes = DashboardPanel(
      sectionId: DashboardSectionIds.tripsTopRoutes,
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

    // One blue ramp, lightest → darkest, matching `tripOccupancyColor`'s
    // buckets — occupancy is "how full", a single dimension, not five
    // unrelated categories.
    final blues = palette.sequential;
    return [
      ChartDatum(label: 'فارغة', value: empty.toDouble(), color: blues[0]),
      ChartDatum(label: 'منخفض', value: low.toDouble(), color: blues[1]),
      ChartDatum(label: 'متوسط', value: mid.toDouble(), color: blues[2]),
      ChartDatum(label: 'مرتفع', value: high.toDouble(), color: blues[3]),
      ChartDatum(label: 'ممتلئة', value: full.toDouble(), color: blues[4]),
    ];
  }

  List<ChartDatum> _topRoutes(DashboardChartPalette palette) {
    final counts = <String, int>{};
    for (final trip in state.trips) {
      counts[trip.route] = (counts[trip.route] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // One consistent blue for every bar: these are routes ranked by the same
    // metric, not distinct categories, so bar length plus the value already
    // shown say everything a colour cycle would only muddy.
    return [
      for (final entry in sorted.take(5))
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: palette.active,
        ),
    ];
  }
}

/// Delegates to [tripStatusColor] — the same accent the list/grouped/timeline
/// rows and the details header use — so the status donut never teaches the
/// operator a colour that means something different one screen over.
Color _statusColor(BuildContext context, OperationTripStatus status) =>
    tripStatusColor(context, status);
