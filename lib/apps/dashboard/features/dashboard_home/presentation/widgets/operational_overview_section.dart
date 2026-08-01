import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// "How is my transportation operation performing today?" — today's trips
/// bucketed into the four states an operator actually thinks in, from the
/// same real trip list the Trips module shows.
class OperationalOverviewSection extends StatelessWidget {
  const OperationalOverviewSection({super.key, required this.summary});

  final DashboardHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final active =
        summary.tripsCountByStatus(OperationTripStatus.inProgress) +
        summary.tripsCountByStatus(OperationTripStatus.boarding);
    final upcoming =
        summary.tripsCountByStatus(OperationTripStatus.scheduled) +
        summary.tripsCountByStatus(OperationTripStatus.openForBooking);
    final completed = summary.tripsCountByStatus(OperationTripStatus.completed);
    final cancelled = summary.tripsCountByStatus(OperationTripStatus.cancelled);

    return DashboardPanel(
      icon: Icons.insights_rounded,
      title: 'نظرة عامة على التشغيل',
      subtitle: 'توزيع رحلات اليوم حسب الحالة',
      child: summary.todayTrips.isEmpty
          ? const EmptyState(
              emoji: '🚌',
              title: 'لا رحلات اليوم',
              subtitle: 'لم يتم جدولة أي رحلة لهذا اليوم بعد.',
            )
          : DashboardDonutChart(
              data: [
                ChartDatum(
                  label: 'الرحلات النشطة',
                  value: active.toDouble(),
                  color: palette.positive,
                ),
                ChartDatum(
                  label: 'الرحلات القادمة',
                  value: upcoming.toDouble(),
                  color: palette.active,
                ),
                ChartDatum(
                  label: 'الرحلات المكتملة',
                  value: completed.toDouble(),
                  color: palette.neutral,
                ),
                ChartDatum(
                  label: 'الرحلات الملغاة',
                  value: cancelled.toDouble(),
                  color: palette.negative,
                ),
              ],
            ),
    );
  }
}
