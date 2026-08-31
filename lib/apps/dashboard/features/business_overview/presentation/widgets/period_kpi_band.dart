import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';

import '../../domain/entities/business_overview.dart';
import '../models/overview_window.dart';
import 'overview_format.dart';

/// The four numbers that describe the selected period — **the same strip
/// الرئيسية opens with**: `DashboardKpiGrid`, `itemExtent: 132`, four
/// `emphasized` tiles, money first, each carrying its own shape and how it
/// moved.
///
/// ## Why four and not ten
///
/// The previous revision put ten tiles here, and six were the wrong shape for a
/// headline strip: two were headcounts with no baseline (so no arrow, so no
/// reason to sit beside eight tiles that had one), two were queue depths that
/// the attention panel states better and *actionably*, and two were wallet
/// figures that only mean something next to the rest of the money. Ten tiles is
/// not a summary — it is a table with the borders removed.
///
/// Money leads here where الرئيسية leads with today's trips, and that is the
/// one deliberate difference between the two strips: Home is the operator's
/// board and opens on what is running, this is the owner's and opens on what
/// it earned. The *shape* is Home's exactly — same grid, same extent, same
/// emphasised tile, same trend wording — because the tile is the same object.
///
/// It was briefly a display-size figure inside a gradient hero, which made this
/// page's opening look nothing like the console's other most-opened screen. A
/// KPI tile with its own sparkline says the same thing in the console's own
/// voice, and the full daily series sits in the panel directly underneath.
///
/// Every tile shows movement **only where a baseline was measured**, and the
/// baseline is the previous window of the same length, named in the chip.
class PeriodKpiBand extends StatelessWidget {
  const PeriodKpiBand({
    super.key,
    required this.overview,
    required this.window,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final OverviewWindow window;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final days = window.days;

    final hasBookings = overview.has(BusinessDataSource.bookings);
    final hasTrips = overview.has(BusinessDataSource.trips);
    final hasReviews = overview.has(BusinessDataSource.reviews);

    final collected = overview.collected(days: days);
    final occupancy = overview.occupancyOver(days: days);
    final satisfaction = overview.satisfaction(days: days);
    final reviewCount = overview.reviews.length;
    final occupancyPercent = ((occupancy ?? 0) * 100).round();

    return DashboardKpiGrid(
      // The stacked tile needs room for label, value, detail *and* the weekly
      // shape along the bottom; anything under ~132 clips the sparkline.
      itemExtent: 132,
      children: [
        DashboardKpiCard(
          emphasized: true,
          label: 'إيراد الفترة',
          value: hasBookings ? money(collected) : '—',
          detail: hasBookings
              ? 'منها اليوم ${money(overview.revenueToday)}'
              : 'تعذّر تحميل الحجوزات',
          icon: DashboardIcons.paymentsActive,
          color: palette.positive,
          trend: hasBookings
              ? kpiTrendFrom(
                  overview.revenueWindowTrend(
                    days: days,
                    previousLabel: window.previous,
                  ),
                  upIsGood: true,
                  absolute: money,
                )
              : null,
          sparkline: hasBookings
              ? sparkValues(overview.revenueSeries(days: days))
              : null,
          onTap: () => onOpenModule(DashboardRoutes.payments),
          tapHint: 'فتح المدفوعات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'حجوزات الفترة',
          value: hasBookings ? count(overview.bookingsOver(days: days)) : '—',
          detail: hasBookings
              ? '${count(overview.bookingsToday)} حجز اليوم'
              : 'تعذّر تحميل الحجوزات',
          icon: DashboardIcons.bookingsActive,
          color: palette.active,
          trend: hasBookings
              ? kpiTrendFrom(
                  overview.bookingsWindowTrend(
                    days: days,
                    previousLabel: window.previous,
                  ),
                  upIsGood: true,
                )
              : null,
          sparkline: hasBookings
              ? sparkValues(overview.bookingsSeries(days: days))
              : null,
          onTap: () => onOpenModule(DashboardRoutes.bookings),
          tapHint: 'فتح الحجوزات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'نسبة الإشغال',
          value: hasTrips ? percentOrDash(occupancy) : '—',
          detail: !hasTrips
              ? 'تعذّر تحميل الرحلات'
              : occupancy == null
              ? 'لا مقاعد معروضة في الفترة'
              : 'مقاعد مباعة من المعروض',
          icon: DashboardIcons.occupancy,
          color: occupancyPercent >= 70 ? palette.positive : scheme.primary,
          trend: hasTrips
              ? kpiTrendFrom(
                  overview.occupancyWindowTrend(
                    days: days,
                    previousLabel: window.previous,
                  ),
                  upIsGood: true,
                  absolute: percent,
                )
              : null,
          sparkline: hasTrips
              ? sparkValues(
                  overview.occupancySeries(days: days),
                )?.map((rate) => rate * 100).toList()
              : null,
          onTap: () => onOpenModule(DashboardRoutes.trips),
          tapHint: 'فتح الرحلات',
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'رضا العملاء',
          value: satisfaction == null
              ? '—'
              : '${satisfaction.toStringAsFixed(1)} / ٥',
          // Phrased as a labelled count rather than "من N تقييم": Arabic
          // agrees the noun with the number across four bands, and a template
          // that picks one form is wrong for most values. Home's panel makes
          // the same sidestep with a colon.
          detail: !hasReviews
              ? 'تعذّر تحميل التقييمات'
              : reviewCount == 0
              ? 'لا تقييمات بعد'
              : 'إجمالي التقييمات: ${count(reviewCount)}',
          icon: DashboardIcons.reviewsActive,
          color: (satisfaction ?? 0) >= 4 ? palette.positive : palette.warning,
          trend: kpiTrendFrom(
            overview.satisfactionTrend(days: days),
            upIsGood: true,
          ),
          onTap: () => onOpenModule(DashboardRoutes.reviews),
          tapHint: 'فتح التقييمات',
        ),
      ],
    );
  }
}
