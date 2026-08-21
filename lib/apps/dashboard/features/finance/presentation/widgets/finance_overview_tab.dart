import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/finance_analytics.dart';
import '../cubit/finance_state.dart';
import 'finance_attention_panel.dart';
import 'finance_common.dart';
import 'finance_format.dart';
import 'finance_money_statements_panel.dart';

/// The thirty-second read.
///
/// The order is the argument: **where the money stands**, then **what needs a
/// decision**, then **which way it is moving**, then **where it comes from**.
/// An earlier revision led with a hero and eight equal KPI tiles, which is a
/// wall rather than a hierarchy — every figure claimed the same importance, and
/// the two the owner had to act on (undecided receipts, pending refunds) were
/// tiles four and eight, with nowhere to go from them.
///
/// The three-statement reconciliation now sits below and starts collapsed. That
/// is safe only because a broken control identity is promoted into the
/// attention panel, so hiding the panel can never hide a break.
class FinanceOverviewTab extends StatelessWidget {
  final FinanceLoaded state;
  final ValueChanged<String>? onOpenModule;

  const FinanceOverviewTab({super.key, required this.state, this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;

    if (state.hasNoHistory) {
      return const _NoHistory();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1 — Money status.
        _NetRevenueHero(state: state),
        const SizedBox(height: AppSpacing.medium),
        _KpiBand(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 2 — What needs a decision.
        FinanceAttentionPanel(
          attention: state.attention,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),

        // 3 — Which way it is moving.
        DashboardPanel(
          sectionId: DashboardSectionIds.financeRevenueTrend,
          icon: Icons.show_chart_rounded,
          title: 'اتجاه الإيراد اليومي',
          subtitle:
              'صافي المحصّل لكل يوم خلال ${analytics.periodLabel} — '
              '${FinanceFormat.count(analytics.activeDays)} يوم فيه تحصيل',
          child: _RevenueTrend(analytics: analytics),
        ),
        const SizedBox(height: AppSpacing.medium),

        // 4 — Where it comes from.
        _ResponsivePair(
          first: DashboardPanel(
            sectionId: DashboardSectionIds.financeRevenueSources,
            icon: Icons.pie_chart_outline_rounded,
            title: 'مصادر الإيراد',
            subtitle: 'حجوزات الرحلات مقابل باقات الاشتراك',
            child: _SourcesChart(analytics: analytics),
          ),
          second: DashboardPanel(
            sectionId: DashboardSectionIds.financePaymentMethods,
            icon: Icons.donut_large_rounded,
            title: 'طرق التحصيل',
            // A package purchase records no rail, so this covers fares only.
            // Without saying so the donut's total reads as *the* revenue and
            // silently disagrees with the headline above it.
            subtitle: 'إيراد الحجوزات حسب وسيلة الدفع — الاشتراكات بلا وسيلة',
            child: _MethodsChart(analytics: analytics),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _ResponsivePair(
          first: DashboardPanel(
            sectionId: DashboardSectionIds.financeTopRoutes,
            icon: Icons.alt_route_rounded,
            title: 'أعلى المسارات إيراداً',
            subtitle: 'ترتيب المسارات حسب الإيراد المحصّل',
            child: FinanceRankedList(
              rows: analytics.byRoute,
              total: analytics.netRevenue,
              labelsAreRoutes: true,
            ),
          ),
          second: DashboardPanel(
            sectionId: DashboardSectionIds.financeTopCustomers,
            icon: Icons.emoji_events_outlined,
            title: 'أعلى العملاء إنفاقاً',
            subtitle: 'العملاء الأكثر مساهمة في إيراد الفترة',
            child: FinanceRankedList(
              rows: analytics.byClient,
              total: analytics.netRevenue,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),

        // 5 — The reconciliation, for when a number is challenged.
        FinanceMoneyStatementsPanel(
          statements: analytics.statements,
          periodLabel: analytics.periodLabel,
        ),
      ],
    );
  }
}

/// An office with no ledger at all is not an office with a bad month. Zeros
/// everywhere would be arithmetically true and completely uninformative.
class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        DashboardEmptyState(
          icon: DashboardIcons.payments,
          title: 'لا توجد حركات مالية بعد',
          message:
              'لم يُسجَّل أي حجز أو اشتراك على هذا المكتب حتى الآن، فلا توجد '
              'أرقام تُعرض. أول عملية بيع ستظهر هنا مباشرة، وستبدأ كل المؤشرات '
              'والتقارير في العمل من تلقاء نفسها.',
        ),
      ],
    );
  }
}

/// A window with no movement says so, instead of drawing a flat line at zero
/// that looks like a chart with data in it.
class _RevenueTrend extends StatelessWidget {
  const _RevenueTrend({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    if (analytics.activeDays == 0) {
      return const DashboardEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'لا يوجد تحصيل في هذه الفترة',
        message: 'لم تُحصَّل أي مبالغ خلال الفترة المختارة — وسّعها للمقارنة.',
      );
    }

    return DashboardLineChart(
      data: [
        for (final point in analytics.daily)
          ChartDatum(
            label: FinanceFormat.shortDate(point.date),
            value: point.net,
            color: palette.active,
          ),
      ],
      lineColor: palette.active,
    );
  }
}

class _SourcesChart extends StatelessWidget {
  const _SourcesChart({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final data = [
      if (analytics.bookingsRevenue > 0)
        ChartDatum(
          label: 'الحجوزات',
          value: analytics.bookingsRevenue,
          color: palette.active,
        ),
      if (analytics.subscriptionsRevenue > 0)
        ChartDatum(
          label: 'الاشتراكات',
          value: analytics.subscriptionsRevenue,
          color: palette.accent,
        ),
    ];

    if (data.isEmpty) {
      return const DashboardEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: 'لا يوجد إيراد محصّل',
        message: 'لم تُحصَّل أي حركة في هذه الفترة، فلا توجد مصادر توزَّع.',
      );
    }

    return DashboardDonutChart(data: data);
  }
}

class _MethodsChart extends StatelessWidget {
  const _MethodsChart({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final data = [
      for (final (index, row) in analytics.byMethod.indexed)
        if (row.amount > 0)
          ChartDatum(
            label: row.label,
            value: row.amount,
            color: palette.categoryAt(index),
          ),
    ];

    if (data.isEmpty) {
      return const DashboardEmptyState(
        icon: Icons.donut_large_rounded,
        title: 'لا توجد عمليات محصّلة',
        message: 'وسيلة الدفع تُسجَّل عند التحصيل فقط.',
      );
    }

    return DashboardDonutChart(data: data);
  }
}

/// The number the owner opens this screen for, with the shape of the period
/// behind it and the arithmetic that produced it spelled out underneath — no
/// single figure on this card is unexplained.
class _NetRevenueHero extends StatelessWidget {
  final FinanceLoaded state;

  const _NetRevenueHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final analytics = state.analytics;
    final scheme = Theme.of(context).colorScheme;
    final previous = analytics.previous;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'صافي الإيراد • ${analytics.periodLabel}',
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
              : 'مقابل ${FinanceFormat.money(previous.netRevenue)} '
                    'في ${analytics.window.previousLabel}',
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
          valueColor: palette.negative,
        ),
        Divider(color: scheme.outlineVariant.withAlpha(120)),
        FinanceFigureRow(
          label: 'صافي الإيراد',
          value: FinanceFormat.money(analytics.netRevenue),
          emphasised: true,
          valueColor: palette.positive,
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'الإيراد بعد المرتجعات فقط — ليس ربحاً: لا تُخصم منه أي تكاليف تشغيل.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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

/// Four figures, not eight.
///
/// The four that went were not wrong, they were redundant or misplaced: booking
/// and subscription revenue are the «مصادر الإيراد» donut directly below,
/// average ticket is a row of the comparison table on التحليلات, and pending
/// refund requests are a queue with an owner, which is the attention panel's
/// job. A KPI band is a summary, and a summary that repeats the chart under it
/// has stopped summarising.
///
/// Four is also the width [DashboardKpiGrid] lays out at desktop sizes. A fifth
/// tile does not make a denser band, it makes a row of four and an orphan with
/// a hole beside it.
class _KpiBand extends StatelessWidget {
  final FinanceLoaded state;

  const _KpiBand({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final analytics = state.analytics;
    final previous = analytics.previous;
    final previousLabel = analytics.window.previousLabel;

    final transactions = _trend(analytics.transactionsChange, previousLabel);
    final refunds = _trend(
      analytics.refundedChange,
      previousLabel,
      inverted: true,
    );
    final collection = _rateTrend(analytics, previous);

    return DashboardKpiGrid(
      // The stacked form only appears when there is a movement to stack; an
      // office with no comparable window would otherwise get four tall tiles
      // with an empty band of nothing under each value.
      itemExtent:
          [transactions, refunds, collection].any((t) => t != null) ? 132 : 92,
      children: [
        DashboardKpiCard(
          icon: Icons.hourglass_bottom_rounded,
          label: 'مستحقات لم تُحصّل',
          value: FinanceFormat.money(analytics.receivable),
          // Kept short on purpose: at 1366 the four-across band gives the
          // detail line about fifteen characters, and a sentence that
          // ellipsises mid-word is worse than a shorter true one.
          detail: '${FinanceFormat.count(analytics.pendingCount)} عملية قائمة',
          color: palette.warning,
        ),
        DashboardKpiCard(
          icon: Icons.verified_outlined,
          label: 'معدل التحصيل',
          value: FinanceFormat.percent(analytics.collectionRate),
          detail: 'من ${FinanceFormat.money(analytics.billed)}',
          color: palette.positive,
          trend: collection,
        ),
        DashboardKpiCard(
          icon: Icons.undo_rounded,
          label: 'المرتجعات المنفذة',
          value: FinanceFormat.money(analytics.refunded),
          detail: '${FinanceFormat.percent(analytics.refundRate)} من المتحصل',
          color: palette.negative,
          trend: refunds,
        ),
        DashboardKpiCard(
          icon: Icons.receipt_long_rounded,
          label: 'عدد المعاملات',
          value: FinanceFormat.count(analytics.transactionCount),
          detail: '${FinanceFormat.count(analytics.paidCount)} منها محصّلة',
          color: palette.active,
          trend: transactions,
        ),
      ],
    );
  }

  /// A movement is shown only when there is a previous window that had
  /// something in it — the dashboard holds no historical snapshots, and a delta
  /// against zero is a division, not a measurement.
  KpiTrend? _trend(
    double? change,
    String previousLabel, {
    bool inverted = false,
  }) {
    if (change == null) return null;
    final isUp = change > 0;
    final isFlat = change == 0;
    final isGood = inverted ? !isUp : isUp;

    return KpiTrend(
      label: isFlat ? 'بدون تغيير' : FinanceFormat.changeLabel(change),
      icon: isFlat
          ? DashboardIcons.trendFlat
          : isUp
          ? DashboardIcons.trendUp
          : DashboardIcons.trendDown,
      tone: isFlat
          ? KpiTrendTone.neutral
          : isGood
          ? KpiTrendTone.positive
          : KpiTrendTone.negative,
      caption: 'مقابل $previousLabel',
    );
  }

  /// The collection rate moves in percentage *points*, not percent — reporting
  /// "94% → 87%" as "−7.4%" is the kind of arithmetic that starts an argument.
  KpiTrend? _rateTrend(FinanceAnalytics analytics, FinanceAnalytics? previous) {
    if (previous == null || previous.billed <= 0) return null;
    final points = (analytics.collectionRate - previous.collectionRate) * 100;
    final isFlat = points.abs() < 0.05;

    return KpiTrend(
      label: isFlat
          ? 'بدون تغيير'
          : '${points > 0 ? '+' : ''}${points.toStringAsFixed(1)} نقطة',
      icon: isFlat
          ? DashboardIcons.trendFlat
          : points > 0
          ? DashboardIcons.trendUp
          : DashboardIcons.trendDown,
      tone: isFlat
          ? KpiTrendTone.neutral
          : points > 0
          ? KpiTrendTone.positive
          : KpiTrendTone.negative,
      caption: 'مقابل ${analytics.window.previousLabel}',
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
