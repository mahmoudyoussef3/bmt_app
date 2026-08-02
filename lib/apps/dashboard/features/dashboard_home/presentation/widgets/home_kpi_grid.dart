import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The four numbers an operator needs within five seconds of landing: today's
/// trips, today's bookings, today's revenue, and how full those trips are.
///
/// Every tile opens the module its figure came from, so "that number looks
/// wrong" is one click from the screen that explains it.
///
/// No trend arrows/percentages: there is no previous-period snapshot anywhere
/// in the schema, and a fabricated "+8%" would be worse than none at all.
/// [DashboardKpiCard.detail] carries real context instead.
class HomeKpiGrid extends StatelessWidget {
  const HomeKpiGrid({super.key, required this.summary, this.onOpenModule});

  final DashboardHomeSummary summary;
  final ValueChanged<String>? onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cancelledToday = summary.tripsCountByStatus(
      OperationTripStatus.cancelled,
    );
    final occupancyPercent = (summary.todayOccupancyRate * 100).round();
    final open = onOpenModule;

    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'رحلات اليوم',
          value: '${summary.todayTripsCount}',
          detail: cancelledToday > 0
              ? '$cancelledToday ملغاة'
              : 'لا رحلات ملغاة',
          icon: DashboardIcons.tripsActive,
          color: palette.active,
          onTap: open == null ? null : () => open(DashboardRoutes.trips),
          tapHint: 'فتح الرحلات',
        ),
        DashboardKpiCard(
          label: 'الحجوزات اليوم',
          value: '${summary.todayBookingsCount}',
          detail: 'من إجمالي ${summary.bookings.length} حجز',
          icon: DashboardIcons.bookingsActive,
          color: palette.active,
          onTap: open == null ? null : () => open(DashboardRoutes.bookings),
          tapHint: 'فتح الحجوزات',
        ),
        DashboardKpiCard(
          label: 'إيرادات اليوم',
          value: '${summary.revenue.todayRevenue.toStringAsFixed(0)} ج.م',
          detail:
              'إجمالي محصّل: ${summary.revenue.grandTotalRevenue.toStringAsFixed(0)} ج.م',
          icon: DashboardIcons.paymentsActive,
          color: palette.positive,
          onTap: open == null ? null : () => open(DashboardRoutes.payments),
          tapHint: 'فتح المدفوعات',
        ),
        DashboardKpiCard(
          label: 'نسبة الإشغال',
          value: summary.todayTrips.isEmpty ? '—' : '$occupancyPercent%',
          detail: summary.todayTrips.isEmpty
              ? 'لا رحلات مجدولة'
              : 'عبر ${summary.todayTripsCount} رحلة',
          icon: DashboardIcons.occupancy,
          color: occupancyPercent >= 70 ? palette.positive : scheme.primary,
          onTap: open == null ? null : () => open(DashboardRoutes.trips),
          tapHint: 'فتح الرحلات',
        ),
      ],
    );
  }
}
