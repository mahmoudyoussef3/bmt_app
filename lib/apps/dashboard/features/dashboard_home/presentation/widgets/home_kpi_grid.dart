import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// The four numbers an operator needs within five seconds of landing: today's
/// trips, today's bookings, today's revenue, and how full those trips are —
/// each with the shape of the last week behind it and how it moved overnight.
///
/// Every tile opens the module its figure came from, so "that number looks
/// wrong" is one click from the screen that explains it.
///
/// **Every movement here was measured, none was invented.** The console holds
/// no historical snapshots, which is why the tiles carried no trend at all for
/// so long. What they carry now is arithmetic over the *same list the headline
/// is counted from* — [DashboardHomeSummary.tripCountsThisWeek] and
/// `todayTripsCount` both read one `trips` list — so a sparkline can never
/// disagree with the number drawn above it, and "up 3 since yesterday" is a
/// fact rather than a guess.
///
/// Revenue is the exception and shows why the rule matters: [RevenueMetrics]
/// reports today, the week and the month as totals with no per-day history, so
/// there is no yesterday to compare and no daily shape to draw. It gets the one
/// baseline that *is* derivable — the week's daily average — and no sparkline,
/// rather than borrowing the booking-collection series next to it and quietly
/// plotting a different measure than the one in the tile.
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
    final noTripsToday = summary.todayTrips.isEmpty;

    return DashboardKpiGrid(
      // The stacked tile needs room for label, value, detail *and* the weekly
      // shape along the bottom; 116 clipped the sparkline off the card.
      itemExtent: 132,
      children: [
        DashboardKpiCard(
          emphasized: true,
          label: 'رحلات اليوم',
          value: '${summary.todayTripsCount}',
          detail: cancelledToday > 0
              ? '$cancelledToday ملغاة'
              : 'لا رحلات ملغاة',
          icon: DashboardIcons.tripsActive,
          color: palette.active,
          trend: _countTrend(summary.tripsDelta, unit: 'رحلة'),
          sparkline: _asDoubles(summary.tripCountsThisWeek),
          onTap: open == null ? null : () => open(DashboardRoutes.trips),
          tapHint: 'فتح الرحلات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'الحجوزات اليوم',
          value: '${summary.todayBookingsCount}',
          detail: 'من إجمالي ${summary.bookings.length} حجز',
          icon: DashboardIcons.bookingsActive,
          color: palette.active,
          trend: _countTrend(summary.bookingsDelta, unit: 'حجز'),
          sparkline: _asDoubles(summary.bookingCountsThisWeek),
          onTap: open == null ? null : () => open(DashboardRoutes.bookings),
          tapHint: 'فتح الحجوزات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'إيرادات اليوم',
          value: '${summary.revenue.todayRevenue.toStringAsFixed(0)} ج.م',
          detail:
              'إجمالي محصّل: ${summary.revenue.grandTotalRevenue.toStringAsFixed(0)} ج.م',
          icon: DashboardIcons.paymentsActive,
          color: palette.positive,
          trend: _averageTrend(summary.revenueAgainstWeeklyAverage),
          onTap: open == null ? null : () => open(DashboardRoutes.payments),
          tapHint: 'فتح المدفوعات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'نسبة الإشغال',
          value: noTripsToday ? '—' : '$occupancyPercent%',
          detail: noTripsToday
              ? 'لا رحلات مجدولة'
              : 'عبر ${summary.todayTripsCount} رحلة',
          icon: DashboardIcons.occupancy,
          color: occupancyPercent >= 70 ? palette.positive : scheme.primary,
          trend: noTripsToday ? null : _pointTrend(summary.occupancyDelta),
          sparkline: [for (final rate in summary.occupancyThisWeek) rate * 100],
          onTap: open == null ? null : () => open(DashboardRoutes.trips),
          tapHint: 'فتح الرحلات',
        ),
      ],
    );
  }
}

List<double> _asDoubles(List<int> series) => [
  for (final value in series) value.toDouble(),
];

/// A whole-number movement — trips, bookings — against yesterday.
///
/// The magnitude only; the arrow carries the sign. A literal `+3` / `−2` is
/// the one place a console like this reliably mis-renders: a sign glyph next
/// to digits inside an RTL line is reordered by the bidi algorithm, and the
/// dash can land on the wrong side of the number. An arrow icon has no
/// direction to lose.
KpiTrend? _countTrend(HomeDelta delta, {required String unit}) {
  if (delta.isFlat) {
    return const KpiTrend(
      label: 'كما أمس',
      icon: DashboardIcons.trendFlat,
      tone: KpiTrendTone.neutral,
    );
  }
  final magnitude = delta.change.abs().round();
  return KpiTrend(
    label: '$magnitude $unit عن أمس',
    icon: delta.isUp ? DashboardIcons.trendUp : DashboardIcons.trendDown,
    tone: delta.isUp ? KpiTrendTone.positive : KpiTrendTone.negative,
  );
}

/// Occupancy moves in percentage *points*, not percent — 60% to 65% is five
/// points, and calling it "+8%" (the share change) would be a different, wrong
/// number. The label says «نقاط» so the two can't be confused.
KpiTrend? _pointTrend(HomeDelta delta) {
  final points = delta.change.round();
  if (points == 0) {
    return const KpiTrend(
      label: 'كما أمس',
      icon: DashboardIcons.trendFlat,
      tone: KpiTrendTone.neutral,
    );
  }
  return KpiTrend(
    label: '${points.abs()} نقاط عن أمس',
    icon: points > 0 ? DashboardIcons.trendUp : DashboardIcons.trendDown,
    tone: points > 0 ? KpiTrendTone.positive : KpiTrendTone.negative,
  );
}

/// Today's revenue against the daily average of its own week. Null when the
/// week collected nothing — there is no share of zero to take.
KpiTrend? _averageTrend(HomeDelta? delta) {
  if (delta == null) return null;
  final percent = delta.percentChange;
  if (percent == null) return null;
  final rounded = percent.round();
  if (rounded == 0) {
    return const KpiTrend(
      label: 'كمتوسط الأسبوع',
      icon: DashboardIcons.trendFlat,
      tone: KpiTrendTone.neutral,
    );
  }
  return KpiTrend(
    label: '${rounded.abs()}% عن المتوسط',
    icon: rounded > 0 ? DashboardIcons.trendUp : DashboardIcons.trendDown,
    tone: rounded > 0 ? KpiTrendTone.positive : KpiTrendTone.negative,
  );
}
