import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The four numbers an operator needs within five seconds of landing: today's
/// trips, today's bookings, today's revenue, and how full those trips are.
///
/// No trend arrows/percentages: there is no previous-period snapshot anywhere
/// in the schema, and a fabricated "+8%" would be worse than none at all.
/// [DashboardKpiCard.detail] carries real context instead.
class HomeKpiGrid extends StatelessWidget {
  const HomeKpiGrid({super.key, required this.summary});

  final DashboardHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cancelledToday = summary.tripsCountByStatus(
      OperationTripStatus.cancelled,
    );
    final occupancyPercent = (summary.todayOccupancyRate * 100).round();

    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'رحلات اليوم',
          value: '${summary.todayTripsCount}',
          detail: cancelledToday > 0 ? '$cancelledToday ملغاة' : 'لا رحلات ملغاة',
          icon: Icons.directions_bus_filled_rounded,
          color: const Color(0xFF0F2747),
        ),
        DashboardKpiCard(
          label: 'الحجوزات اليوم',
          value: '${summary.todayBookingsCount}',
          detail: 'من إجمالي ${summary.bookings.length} حجز',
          icon: Icons.event_seat_rounded,
          color: const Color(0xFF2F80ED),
        ),
        DashboardKpiCard(
          label: 'إيرادات اليوم',
          value: '${summary.revenue.todayRevenue.toStringAsFixed(0)} ج.م',
          detail:
              'إجمالي محصّل: ${summary.revenue.grandTotalRevenue.toStringAsFixed(0)} ج.م',
          icon: Icons.payments_rounded,
          color: const Color(0xFF22A06B),
        ),
        DashboardKpiCard(
          label: 'نسبة الإشغال',
          value: summary.todayTrips.isEmpty ? '—' : '$occupancyPercent%',
          detail: summary.todayTrips.isEmpty
              ? 'لا رحلات اليوم'
              : 'عبر ${summary.todayTripsCount} رحلة',
          icon: Icons.pie_chart_rounded,
          color: occupancyPercent >= 70
              ? const Color(0xFF22A06B)
              : scheme.primary,
        ),
      ],
    );
  }
}
