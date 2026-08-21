import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

import '../../domain/entities/customer_profile.dart';
import '../cubit/customer_profile_state.dart';
import 'customers_format.dart';

/// نظرة عامة — what the office knows about this customer, in one screen.
///
/// Arrives with the header in a single round trip, so the tab the operator
/// lands on never shows a spinner.
class CustomerOverviewTab extends StatelessWidget {
  const CustomerOverviewTab({
    super.key,
    required this.state,
    required this.now,
  });

  final CustomerProfileLoadedState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final metrics = state.profile.metrics;
    final palette = DashboardChartPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardKpiGrid(
          maxColumns: 4,
          children: [
            DashboardKpiCard(
              label: 'إجمالي الحجوزات',
              value: CustomersFormat.count(metrics.bookingsTotal),
              icon: DashboardIcons.bookings,
              detail: 'مع هذا المكتب',
              color: palette.active,
            ),
            DashboardKpiCard(
              label: 'الرحلات المكتملة',
              value: CustomersFormat.count(metrics.bookingsCompleted),
              icon: DashboardIcons.allClear,
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'الرحلات القادمة',
              value: CustomersFormat.count(metrics.bookingsUpcoming),
              icon: DashboardIcons.trips,
              detail: metrics.nextTripDate == null
                  ? 'لا توجد رحلات قادمة'
                  : 'أقربها ${CustomersFormat.relativeDay(metrics.nextTripDate, now)}',
              color: palette.warning,
            ),
            DashboardKpiCard(
              label: 'الحجوزات الملغاة',
              value: CustomersFormat.count(metrics.bookingsCancelled),
              icon: Icons.cancel_outlined,
              // The share is only shown once there are enough bookings for it
              // to mean anything — see CustomerMetrics.cancellationRate.
              detail: metrics.cancellationRate == null
                  ? null
                  : '${(metrics.cancellationRate! * 100).round()}٪ من حجوزاته',
              color: palette.negative,
            ),
            DashboardKpiCard(
              label: 'إجمالي المدفوعات',
              value: CustomersFormat.money(metrics.totalPaid),
              icon: DashboardIcons.payments,
              detail:
                  '${CustomersFormat.count(metrics.paymentsCount)} عملية دفع',
              color: palette.positive,
            ),
            DashboardKpiCard(
              label: 'رصيد المحفظة',
              // Null is not zero: the office has never opened a wallet here.
              value: metrics.walletBalance == null
                  ? '—'
                  : CustomersFormat.moneyPrecise(metrics.walletBalance!),
              icon: DashboardIcons.wallet,
              detail: metrics.walletBalance == null
                  ? 'لا توجد محفظة لهذا العميل'
                  : null,
              color: palette.accent,
            ),
            DashboardKpiCard(
              label: 'الاشتراكات',
              value: CustomersFormat.count(metrics.subscriptionsTotal),
              icon: DashboardIcons.subscriptions,
              detail: metrics.activeSubscriptions > 0
                  ? '${metrics.activeSubscriptions} ساري'
                  : 'لا يوجد اشتراك ساري',
              color: palette.accent,
            ),
            DashboardKpiCard(
              label: 'آخر نشاط',
              value: CustomersFormat.age(metrics.lastActivityAt, now),
              icon: DashboardIcons.activity,
              color: palette.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final subscription = _CurrentSubscription(state: state, now: now);
            final behaviour = _TravelBehaviour(metrics: metrics);

            // Each column needs ~380px to be readable; below that they stack.
            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  subscription,
                  const SizedBox(height: AppSpacing.medium),
                  behaviour,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: subscription),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: behaviour),
              ],
            );
          },
        ),
        if (state.profile.topRoutes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          _PreferredRoutes(routes: state.profile.topRoutes),
        ],
      ],
    );
  }
}

class _CurrentSubscription extends StatelessWidget {
  const _CurrentSubscription({required this.state, required this.now});

  final CustomerProfileLoadedState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final subscription = state.profile.activeSubscription;

    return DashboardPanel(
      icon: DashboardIcons.subscriptions,
      title: 'الاشتراك الحالي',
      child: subscription == null
          ? Text(
              'لا يوجد اشتراك ساري لهذا العميل.',
              style: TextStyle(color: DashboardColors.mutedInk(context)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.packageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (subscription.routeName != null) ...[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    subscription.routeName!,
                    style: TextStyle(
                      color: DashboardColors.mutedInk(context),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.medium),
                _Row(
                  label: 'المدة',
                  value: subscription.startDate == null
                      ? '—'
                      : '${CustomersFormat.date(subscription.startDate!)}'
                            ' — '
                            '${subscription.endDate == null ? 'غير محدد' : CustomersFormat.date(subscription.endDate!)}',
                ),
                _Row(
                  label: 'الرحلات',
                  value:
                      '${subscription.tripsUsed} مستخدمة من ${subscription.tripsCount}',
                ),
                _Row(
                  label: 'المتبقي',
                  value: '${subscription.tripsRemaining} رحلة',
                ),
                if (subscription.daysRemaining(now) != null)
                  _Row(
                    label: 'ينتهي خلال',
                    value: subscription.daysRemaining(now)! < 0
                        ? 'انتهى'
                        : '${subscription.daysRemaining(now)} يوم',
                  ),
                // Omitted entirely when the package has no ride allowance —
                // a 0% bar would read as "used nothing" rather than
                // "not measurable".
                if (subscription.usageFraction != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  _UsageBar(
                    fraction: subscription.usageFraction!,
                    percent: subscription.usagePercent!,
                  ),
                ],
              ],
            ),
    );
  }
}

class _TravelBehaviour extends StatelessWidget {
  const _TravelBehaviour({required this.metrics});

  final CustomerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final boarding = metrics.boardingRate;

    return DashboardPanel(
      icon: DashboardIcons.occupancy,
      title: 'سلوك السفر',
      subtitle: 'كيف يستخدم هذا العميل الخدمة فعلياً',
      sectionId: DashboardSectionIds.customerProfileBehaviour,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'مرات الصعود',
            value: CustomersFormat.count(metrics.boardedCount),
          ),
          _Row(
            label: 'مرات عدم الحضور',
            value: CustomersFormat.count(metrics.noShowCount),
          ),
          // Cancellations are not repeated here — the KPI row above already
          // carries the count and its share. Printing the same figure twice on
          // one tab invites the reader to look for the difference.
          // Null while no manifest row has reached a verdict — a trip still
          // marked `reserved` has not yet said anything about attendance.
          if (boarding != null)
            _Row(label: 'نسبة الحضور', value: '${(boarding * 100).round()}٪'),
          if (metrics.reviewsCount > 0)
            _Row(
              label: 'التقييمات',
              value: metrics.avgOfficeRating == null
                  ? '${metrics.reviewsCount} تقييم'
                  : '${metrics.reviewsCount} تقييم · متوسط ${metrics.avgOfficeRating!.toStringAsFixed(1)} للمكتب',
            ),
          if (metrics.ticketsTotal > 0)
            _Row(
              label: 'الشكاوى',
              value: metrics.ticketsOpen > 0
                  ? '${metrics.ticketsTotal} — منها ${metrics.ticketsOpen} مفتوحة'
                  : '${metrics.ticketsTotal} — كلها مغلقة',
            ),
          if (metrics.refundsSettledAmount > 0)
            _Row(
              label: 'المبالغ المستردة',
              value: CustomersFormat.money(metrics.refundsSettledAmount),
            ),
          if (metrics.boardedCount == 0 &&
              metrics.noShowCount == 0 &&
              metrics.bookingsCancelled == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xSmall),
              child: Text(
                'لا توجد بيانات صعود مسجّلة لهذا العميل بعد.',
                style: TextStyle(color: DashboardColors.mutedInk(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreferredRoutes extends StatelessWidget {
  const _PreferredRoutes({required this.routes});

  final List<CustomerRoute> routes;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final max = routes.first.trips;

    return DashboardPanel(
      icon: DashboardIcons.routes,
      title: 'المسارات الأكثر استخداماً',
      subtitle: 'مشتقة من حجوزات العميل نفسه',
      sectionId: DashboardSectionIds.customerProfileRoutes,
      child: Column(
        children: [
          for (var i = 0; i < routes.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                Expanded(
                  child: Text(
                    routes[i].route,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : routes[i].trips / max,
                      minHeight: 8,
                      backgroundColor: palette.neutral.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(palette.categoryAt(i)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  '${routes[i].trips}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.fraction, required this.percent});

  final double fraction;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الاستخدام',
              style: TextStyle(color: DashboardColors.mutedInk(context)),
            ),
            Text(
              '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}٪',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        AppProgressBar(progress: fraction),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: DashboardColors.mutedInk(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
