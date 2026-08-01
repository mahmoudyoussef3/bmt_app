import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/finance_analytics.dart';
import '../cubit/finance_state.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// The answer to "how did we do?" in one screen: the headline number, what it
/// is made of, and where it came from.
class FinanceOverviewTab extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceOverviewTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _NetRevenueHero(state: state),
        const SizedBox(height: AppSpacing.medium),
        _KpiBand(state: state),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          icon: Icons.show_chart_rounded,
          title: 'اتجاه الإيراد اليومي',
          subtitle:
              'صافي المحصّل لكل يوم خلال ${analytics.period.label} — ${FinanceFormat.count(analytics.activeDays)} يوم فيه تحصيل',
          child: DashboardLineChart(
            data: [
              for (final point in analytics.daily)
                ChartDatum(
                  label: FinanceFormat.shortDate(point.date),
                  value: point.net,
                  color: DashboardChartPalette.active,
                ),
            ],
            lineColor: DashboardChartPalette.active,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _ResponsivePair(
          first: DashboardPanel(
            icon: Icons.pie_chart_outline_rounded,
            title: 'مصادر الإيراد',
            subtitle: 'حجوزات الرحلات مقابل باقات الاشتراك',
            child: DashboardDonutChart(data: _sourceData(analytics)),
          ),
          second: DashboardPanel(
            icon: Icons.donut_large_rounded,
            title: 'طرق التحصيل',
            subtitle: 'الإيراد المحصّل حسب وسيلة الدفع',
            child: DashboardDonutChart(data: _methodData(analytics)),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _ResponsivePair(
          first: DashboardPanel(
            icon: Icons.alt_route_rounded,
            title: 'أعلى المسارات إيراداً',
            subtitle: 'ترتيب المسارات حسب الإيراد المحصّل',
            child: FinanceRankedList(
              rows: analytics.byRoute,
              total: analytics.netRevenue,
            ),
          ),
          second: DashboardPanel(
            icon: Icons.emoji_events_outlined,
            title: 'أعلى العملاء إنفاقاً',
            subtitle: 'العملاء الأكثر مساهمة في إيراد الفترة',
            child: FinanceRankedList(
              rows: analytics.byClient,
              total: analytics.netRevenue,
            ),
          ),
        ),
      ],
    );
  }

  List<ChartDatum> _sourceData(FinanceAnalytics analytics) => [
    if (analytics.bookingsRevenue > 0)
      ChartDatum(
        label: 'الحجوزات',
        value: analytics.bookingsRevenue,
        color: DashboardChartPalette.active,
      ),
    if (analytics.subscriptionsRevenue > 0)
      ChartDatum(
        label: 'الاشتراكات',
        value: analytics.subscriptionsRevenue,
        color: DashboardChartPalette.accent,
      ),
  ];

  List<ChartDatum> _methodData(FinanceAnalytics analytics) => [
    for (final (index, row) in analytics.byMethod.indexed)
      if (row.amount > 0)
        ChartDatum(
          label: row.label,
          value: row.amount,
          color: DashboardChartPalette.categoryAt(index),
        ),
  ];
}

/// The number the owner opens this screen for, with the shape of the period
/// behind it and the arithmetic that produced it spelled out underneath — no
/// single figure on this card is unexplained.
class _NetRevenueHero extends StatelessWidget {
  final FinanceLoaded state;

  const _NetRevenueHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;
    final scheme = Theme.of(context).colorScheme;
    final previous = analytics.previous;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'صافي الإيراد • ${analytics.period.label}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            FinanceFormat.money(analytics.netRevenue),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        FinanceDeltaBadge(
          change: analytics.netRevenueChange,
          caption: previous == null
              ? null
              : 'مقابل ${FinanceFormat.money(previous.netRevenue)} في الفترة السابقة',
        ),
      ],
    );

    final breakdown = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FinanceFigureRow(
          label: 'إجمالي المتحصلات',
          value: FinanceFormat.money(analytics.grossReceived),
        ),
        FinanceFigureRow(
          label: 'المرتجعات المنفذة',
          value: '− ${FinanceFormat.money(analytics.refunded)}',
          valueColor: DashboardChartPalette.negative,
        ),
        Divider(color: scheme.outlineVariant.withAlpha(120)),
        FinanceFigureRow(
          label: 'صافي الإيراد',
          value: FinanceFormat.money(analytics.netRevenue),
          emphasised: true,
          valueColor: DashboardChartPalette.positive,
        ),
      ],
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [scheme.primary.withAlpha(22), scheme.primary.withAlpha(6)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sparkline = FinanceSparkline(
              values: [for (final point in analytics.daily) point.net],
              color: scheme.primary,
              height: 64,
            );

            if (constraints.maxWidth < 820) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headline,
                  const SizedBox(height: AppSpacing.medium),
                  sparkline,
                  const SizedBox(height: AppSpacing.medium),
                  breakdown,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: headline),
                const SizedBox(width: AppSpacing.large),
                Expanded(flex: 4, child: sparkline),
                const SizedBox(width: AppSpacing.large),
                Expanded(flex: 4, child: breakdown),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiBand extends StatelessWidget {
  final FinanceLoaded state;

  const _KpiBand({required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;

    return DashboardKpiGrid(
      itemExtent: 92,
      children: [
        DashboardKpiCard(
          icon: Icons.receipt_long_rounded,
          label: 'عدد المعاملات',
          value: FinanceFormat.count(analytics.transactionCount),
          detail:
              '${FinanceFormat.count(analytics.paidCount)} محصّلة • ${FinanceFormat.count(analytics.pendingCount)} معلقة',
          color: DashboardChartPalette.active,
        ),
        DashboardKpiCard(
          icon: Icons.confirmation_number_outlined,
          label: 'متوسط قيمة المعاملة',
          value: FinanceFormat.money(analytics.averageTicket),
          detail: analytics.hasComparison
              ? 'التغير ${FinanceFormat.changeLabel(analytics.averageTicketChange)}'
              : 'متوسط العملية المحصّلة',
          color: DashboardChartPalette.accent,
        ),
        DashboardKpiCard(
          icon: Icons.hourglass_bottom_rounded,
          label: 'قيد التحصيل',
          value: FinanceFormat.money(analytics.pending),
          detail: '${FinanceFormat.count(analytics.pendingCount)} عملية معلقة',
          color: DashboardChartPalette.warning,
        ),
        DashboardKpiCard(
          icon: Icons.verified_outlined,
          label: 'معدل التحصيل',
          value: FinanceFormat.percent(analytics.collectionRate),
          detail: 'من إجمالي ${FinanceFormat.money(analytics.billed)} مفوترة',
          color: DashboardChartPalette.positive,
        ),
        DashboardKpiCard(
          icon: Icons.directions_bus_filled_outlined,
          label: 'إيراد الحجوزات',
          value: FinanceFormat.money(analytics.bookingsRevenue),
          detail: FinanceFormat.percent(
            analytics.netRevenue <= 0
                ? 0
                : analytics.bookingsRevenue / analytics.netRevenue,
          ),
          color: DashboardChartPalette.active,
        ),
        DashboardKpiCard(
          icon: Icons.workspace_premium_outlined,
          label: 'إيراد الاشتراكات',
          value: FinanceFormat.money(analytics.subscriptionsRevenue),
          detail:
              '${FinanceFormat.count(state.activeSubscriptions)} اشتراك نشط حالياً',
          color: DashboardChartPalette.accent,
        ),
        DashboardKpiCard(
          icon: Icons.undo_rounded,
          label: 'المرتجعات المنفذة',
          value: FinanceFormat.money(analytics.refunded),
          detail:
              'نسبة ${FinanceFormat.percent(analytics.refundRate)} من المتحصلات',
          color: DashboardChartPalette.negative,
        ),
        DashboardKpiCard(
          icon: Icons.pending_actions_outlined,
          label: 'طلبات استرداد معلقة',
          value: FinanceFormat.money(state.pendingRefundAmount),
          detail:
              '${FinanceFormat.count(state.pendingRefundRequests.length)} طلب بانتظار القرار',
          color: DashboardChartPalette.warning,
        ),
      ],
    );
  }
}

/// Two panels side by side on wide screens, stacked below 980px — the width the
/// rest of the dashboard's analytics sections already break at.
class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.medium),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
