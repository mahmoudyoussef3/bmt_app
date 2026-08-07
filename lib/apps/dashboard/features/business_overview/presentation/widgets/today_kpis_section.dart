import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';

import '../../domain/entities/business_overview.dart';
import 'overview_format.dart';

/// Section 1 — the ten figures that describe today.
///
/// Every tile carries its value, a comparison where one is *measurable*, and
/// the shape of the last seven days. Where the schema cannot support a
/// comparison — headcounts and open queues have no history in any table — the
/// tile shows a context line instead of an arrow. That asymmetry is deliberate:
/// a page where eight tiles have trends and two do not is honest, and a page
/// where all ten do is not.
class TodayKpisSection extends StatelessWidget {
  const TodayKpisSection({
    super.key,
    required this.overview,
    required this.onOpenModule,
  });

  final BusinessOverview overview;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    final hasBookings = overview.has(BusinessDataSource.bookings);
    final hasTrips = overview.has(BusinessDataSource.trips);
    final hasFleet = overview.has(BusinessDataSource.fleet);
    final hasWallet = overview.has(BusinessDataSource.wallet);
    final hasRefunds = overview.has(BusinessDataSource.refunds);
    final hasReviews = overview.has(BusinessDataSource.reviews);

    final occupancy = overview.occupancyToday;
    final satisfaction = overview.satisfaction();
    final reviewCount = overview.reviews.length;

    return DashboardPanel(
      sectionId: DashboardSectionIds.businessKpis,
      icon: DashboardIcons.trend,
      title: 'مؤشرات اليوم',
      subtitle: 'مقارنة بالأمس، وشكل آخر ٧ أيام',
      collapsedSummary: _CollapsedSummary(overview: overview),
      child: DashboardKpiGrid(
        itemExtent: 132,
        children: [
          DashboardKpiCard(
            label: 'إيراد الحجوزات اليوم',
            value: hasBookings ? money(overview.revenueToday) : '—',
            detail: hasBookings ? null : 'تعذّر تحميل الحجوزات',
            icon: DashboardIcons.revenue,
            color: palette.positive,
            trend: hasBookings
                ? kpiTrendFrom(
                    overview.revenueTrend,
                    upIsGood: true,
                    absolute: money,
                  )
                : null,
            sparkline: hasBookings ? sparkValues(overview.revenueWeek) : null,
            onTap: () => onOpenModule(DashboardRoutes.payments),
            tapHint: 'فتح المدفوعات',
          ),
          DashboardKpiCard(
            label: 'حجوزات وردت اليوم',
            value: hasBookings ? count(overview.bookingsToday) : '—',
            icon: DashboardIcons.bookingsActive,
            color: palette.active,
            trend: hasBookings
                ? kpiTrendFrom(overview.bookingsTrend, upIsGood: true)
                : null,
            sparkline: hasBookings ? sparkValues(overview.bookingsWeek) : null,
            onTap: () => onOpenModule(DashboardRoutes.bookings),
            tapHint: 'فتح الحجوزات',
          ),
          DashboardKpiCard(
            label: 'رحلات اليوم',
            value: hasTrips ? count(overview.tripsToday) : '—',
            detail: hasTrips
                ? '${count(overview.tripsRunningNow)} جارية الآن'
                : 'تعذّر تحميل الرحلات',
            icon: DashboardIcons.tripsActive,
            color: palette.active,
            trend: hasTrips
                ? kpiTrendFrom(overview.tripsTrend, upIsGood: true)
                : null,
            sparkline: hasTrips ? sparkValues(overview.tripsWeek) : null,
            onTap: () => onOpenModule(DashboardRoutes.trips),
            tapHint: 'فتح الرحلات',
          ),
          DashboardKpiCard(
            label: 'نسبة الإشغال',
            value: hasTrips && overview.tripsToday > 0
                ? percent(occupancy)
                : '—',
            detail: overview.tripsToday == 0 ? 'لا رحلات مجدولة اليوم' : null,
            icon: DashboardIcons.occupancy,
            color: occupancy >= 0.70 ? palette.positive : scheme.primary,
            trend: hasTrips
                ? kpiTrendFrom(overview.occupancyTrend, upIsGood: true)
                : null,
            sparkline: hasTrips ? sparkValues(overview.occupancyWeek) : null,
            onTap: () => onOpenModule(DashboardRoutes.trips),
            tapHint: 'فتح الرحلات',
          ),
          DashboardKpiCard(
            label: 'سائقون في الخدمة',
            value: hasTrips ? count(overview.driversOnDuty) : '—',
            // No arrow: nothing in the schema records how many drivers were
            // rostered yesterday, so a comparison here would be invented.
            detail: hasFleet
                ? 'من ${count(overview.activeDrivers)} سائقاً نشطاً'
                : 'رحلات اليوم',
            icon: DashboardIcons.captains,
            color: scheme.primary,
            onTap: () => onOpenModule(DashboardRoutes.drivers),
            tapHint: 'فتح السائقين',
          ),
          DashboardKpiCard(
            label: 'مركبات على الطريق',
            value: hasTrips ? count(overview.vehiclesOnRoad) : '—',
            detail: hasFleet
                ? 'من ${count(overview.activeVehicles)} مركبة نشطة'
                : 'رحلات اليوم',
            icon: DashboardIcons.vehicle,
            color: scheme.primary,
            onTap: () => onOpenModule(DashboardRoutes.vehicles),
            tapHint: 'فتح المركبات',
          ),
          DashboardKpiCard(
            label: 'مدفوعات بانتظار المراجعة',
            value: overview.has(BusinessDataSource.paymentVerifications)
                ? count(overview.pendingPaymentReviews.length)
                : '—',
            detail: '${money(overview.outstanding)} لم تُحصّل',
            icon: DashboardIcons.paymentReview,
            color: overview.pendingPaymentReviews.isEmpty
                ? scheme.primary
                : palette.warning,
            onTap: () => onOpenModule(DashboardRoutes.paymentVerification),
            tapHint: 'فتح مراجعة المدفوعات',
          ),
          DashboardKpiCard(
            label: 'طلبات استرداد معلّقة',
            value: hasRefunds ? count(overview.pendingRefunds.length) : '—',
            detail: hasRefunds
                ? '${money(overview.pendingRefundAmount)} بانتظار قرارك'
                : 'تعذّر تحميل طلبات الاسترداد',
            icon: DashboardIcons.wallet,
            color: overview.pendingRefunds.isEmpty
                ? scheme.primary
                : palette.negative,
            onTap: () => onOpenModule(DashboardRoutes.wallet),
            tapHint: 'فتح محفظة العملاء',
          ),
          DashboardKpiCard(
            label: 'تغيّر أرصدة المحافظ اليوم',
            value: hasWallet ? signedMoney(overview.walletChangeToday) : '—',
            detail: hasWallet
                ? 'الالتزام الحالي ${money(overview.walletLiability)}'
                : 'تعذّر تحميل المحافظ',
            icon: DashboardIcons.walletActive,
            color: palette.accent,
            trend: hasWallet
                ? kpiTrendFrom(
                    overview.walletTrend,
                    // A wallet balance climbing is money the office owes back,
                    // not money it earned.
                    upIsGood: false,
                    absolute: money,
                  )
                : null,
            sparkline: hasWallet ? sparkValues(overview.walletWeek) : null,
            onTap: () => onOpenModule(DashboardRoutes.wallet),
            tapHint: 'فتح محفظة العملاء',
          ),
          DashboardKpiCard(
            label: 'رضا العملاء',
            value: satisfaction == null
                ? '—'
                : '${satisfaction.toStringAsFixed(1)} / ٥',
            detail: hasReviews
                ? (reviewCount == 0
                      ? 'لا تقييمات بعد'
                      : 'من ${count(reviewCount)} تقييم')
                : 'تعذّر تحميل التقييمات',
            icon: DashboardIcons.reviews,
            color: (satisfaction ?? 0) >= 4 ? palette.positive : palette.warning,
            trend: kpiTrendFrom(overview.satisfactionTrend(), upIsGood: true),
            onTap: () => onOpenModule(DashboardRoutes.reviews),
            tapHint: 'فتح التقييمات',
          ),
        ],
      ),
    );
  }
}

/// What a folded KPI strip still has to say. Money and today's load, because
/// those are the two an owner reopens the section to check.
class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary({required this.overview});

  final BusinessOverview overview;

  @override
  Widget build(BuildContext context) {
    return Text(
      'إيراد اليوم ${money(overview.revenueToday)} · '
      '${count(overview.bookingsToday)} حجز · '
      '${count(overview.tripsToday)} رحلة · '
      'إشغال ${percent(overview.occupancyToday)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
