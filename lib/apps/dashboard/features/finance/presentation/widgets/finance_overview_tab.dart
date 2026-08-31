import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';
import 'finance_attention_panel.dart';
import 'finance_common.dart';
import 'finance_format.dart';
import 'finance_money_statements_panel.dart';

/// The thirty-second read.
///
/// The order is the argument: **where the money stands**, then **what needs a
/// decision**, then **where it comes from**. An earlier revision led with a
/// hero and eight equal KPI tiles, which is a wall rather than a hierarchy —
/// every figure claimed the same importance, and the two the owner had to act
/// on (undecided receipts, pending refunds) were tiles four and eight, with
/// nowhere to go from them.
///
/// The three-statement reconciliation sits last and starts collapsed. That is
/// safe only because a broken control identity is promoted into the attention
/// panel, so hiding the panel can never hide a break.
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
        // 1 — Where the money stands, and the shape of the period behind it.
        FinanceMoneyPositionCard(state: state),
        const SizedBox(height: AppSpacing.medium),
        _KpiBand(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 2 — What needs a decision.
        FinanceAttentionPanel(
          attention: state.attention,
          onOpenModule: onOpenModule,
        ),
        const SizedBox(height: AppSpacing.medium),

        // 3 — Where it comes from.
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

        // 4 — The reconciliation, for when a number is challenged.
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

/// The number the owner opens this screen for, the shape of the period that
/// produced it, and the arithmetic behind it — one card, in that order.
///
/// It replaces two blocks that used to be separate: a hero whose middle third
/// was an unlabelled sparkline floating in white space, and a full «اتجاه
/// الإيراد اليومي» panel below it drawing the *same series* properly. Keeping
/// both meant the page said the same thing twice and neither said it well; the
/// headline now sits beside the real chart, and the sparkline is gone.
///
/// The breakdown moved out of a third column and under a rule, as an equation
/// read across the card. In three columns the label and its value were pushed
/// to opposite ends of a 300px lane — «إجمالي المتحصلات» on one side and
/// «17,327 ج.م» on the other, with nothing between them but distance.
class FinanceMoneyPositionCard extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceMoneyPositionCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final headline = _Headline(analytics: analytics);
                final trend = _RevenueTrend(analytics: analytics);

                if (constraints.maxWidth <
                    MediaQuery.textScalerOf(context).scale(880)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headline,
                      const SizedBox(height: AppSpacing.large),
                      trend,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: headline),
                    const SizedBox(width: AppSpacing.large),
                    Expanded(flex: 7, child: trend),
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: DashboardColors.divider(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              AppSpacing.medium,
              AppSpacing.large,
              AppSpacing.medium,
            ),
            child: _RevenueEquation(analytics: analytics),
          ),
        ],
      ),
    );
  }
}

/// Label, figure, movement. Nothing else competes for the top-left of the page.
class _Headline extends StatelessWidget {
  const _Headline({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = DashboardColors.accentInk(context);
    final previous = analytics.previous;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: DashboardColors.kpiTint(context, accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.savings_rounded, size: 16, color: accent),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              'صافي الإيراد',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: DashboardColors.mutedInk(context),
              ),
            ),
            const SizedBox(width: 6),
            // The window, restated on the card. The toolbar above says it too,
            // but a figure this size gets screenshotted and pasted into a
            // message on its own, and «16,559 ج.م» with no period on it is a
            // number nobody can check.
            Expanded(
              child: Text(
                '· ${analytics.periodLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DashboardColors.faintInk(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            FinanceFormat.money(analytics.netRevenue),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              fontFeatures: const [FontFeature.tabularFigures()],
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
  }
}

/// The daily series, drawn once and properly — axis, grid and all.
///
/// A window with no movement says so, instead of drawing a flat line at zero
/// that looks like a chart with data in it.
class _RevenueTrend extends StatelessWidget {
  const _RevenueTrend({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardChartPalette.of(context);

    final header = Row(
      children: [
        Icon(
          Icons.show_chart_rounded,
          size: 16,
          color: DashboardColors.mutedInk(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'التحصيل اليومي',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
        Text(
          '${FinanceFormat.count(analytics.activeDays)} يوم فيه تحصيل',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: DashboardColors.faintInk(context),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        const SizedBox(height: AppSpacing.small),
        if (analytics.activeDays == 0)
          // Deliberately unconstrained: the empty state is taller than the
          // 196px the chart occupies, and boxing it to the chart's height to
          // keep the card the same size clips its own message.
          const DashboardEmptyState(
            icon: Icons.show_chart_rounded,
            title: 'لا يوجد تحصيل في هذه الفترة',
            message:
                'لم تُحصَّل أي مبالغ خلال الفترة المختارة — وسّعها للمقارنة.',
          )
        else
          DashboardLineChart(
            data: [
              for (final point in analytics.daily)
                ChartDatum(
                  label: FinanceFormat.shortDate(point.date),
                  value: point.net,
                  color: palette.active,
                ),
            ],
            lineColor: DashboardColors.accentFill(context),
          ),
      ],
    );
  }
}

/// `إجمالي المتحصلات − المرتجعات المنفذة = صافي الإيراد`, read across the card.
///
/// An equation rather than a table because that is what it is, and because
/// three label/value pairs in three stretched rows put every label a third of a
/// screen away from the number it names.
class _RevenueEquation extends StatelessWidget {
  const _RevenueEquation({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.large,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Figure(
              label: 'إجمالي المتحصلات',
              value: FinanceFormat.money(analytics.grossReceived),
            ),
            const _Operator('−'),
            _Figure(
              label: 'المرتجعات المنفذة',
              value: FinanceFormat.money(analytics.refunded),
              color: analytics.refunded > 0 ? palette.negative : null,
            ),
            const _Operator('='),
            _Figure(
              label: 'صافي الإيراد',
              value: FinanceFormat.money(analytics.netRevenue),
              color: palette.positive,
              emphasised: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'الإيراد بعد المرتجعات فقط — ليس ربحاً: لا تُخصم منه أي تكاليف تشغيل.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DashboardColors.faintInk(context),
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.color,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (emphasised
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
        ),
      ],
    );
  }
}

class _Operator extends StatelessWidget {
  const _Operator(this.glyph);

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        glyph,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: DashboardColors.faintInk(context),
          fontWeight: FontWeight.w700,
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
/// Every tile is `emphasized`, which is not decoration: the tile only takes the
/// stacked shape when it has a trend to stack, so a band where three figures
/// have a comparable previous window and one does not used to render three
/// tall tiles and one short one with its value floating in the middle. Forcing
/// the shape makes the band a band.
///
/// Three of the four open the ledger already filtered to the rows they counted.
/// That is still reading — a filter is not a decision — and it is the shortest
/// path from "that number looks wrong" to the rows behind it.
class _KpiBand extends StatelessWidget {
  final FinanceLoaded state;

  const _KpiBand({required this.state});

  /// Opens الحركات المالية scoped to one payment status, from a clean slate so
  /// a filter left behind on an earlier visit cannot narrow what the tile
  /// promised to show.
  void _openLedger(BuildContext context, {PaymentStatus? status}) {
    final cubit = context.read<FinanceCubit>();
    cubit.clearFilters();
    if (status != null) cubit.setStatusFilter(status);
    cubit.selectSection(FinanceSection.ledger);
  }

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
      itemExtent: 132,
      children: [
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.hourglass_bottom_rounded,
          label: 'مستحقات لم تُحصّل',
          value: FinanceFormat.money(analytics.receivable),
          // Kept short on purpose: at 1366 the four-across band gives the
          // detail line about fifteen characters, and a sentence that
          // ellipsises mid-word is worse than a shorter true one.
          detail: '${FinanceFormat.count(analytics.pendingCount)} عملية قائمة',
          color: palette.warning,
          onTap: analytics.pendingCount == 0
              ? null
              : () => _openLedger(context, status: PaymentStatus.pending),
          // Says what the tap lands on rather than restating the tile: the
          // figure also carries the unpaid tail of part-paid packages, which
          // sit on collected rows and so are not in the قيد التحصيل list.
          tapHint: analytics.pendingCount == 0
              ? null
              : 'اعرض العمليات القائمة في السجل',
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.verified_outlined,
          label: 'معدل التحصيل',
          value: FinanceFormat.percent(analytics.collectionRate),
          detail: 'من ${FinanceFormat.money(analytics.billed)}',
          color: palette.positive,
          trend: collection,
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.undo_rounded,
          label: 'المرتجعات المنفذة',
          value: FinanceFormat.money(analytics.refunded),
          detail: '${FinanceFormat.percent(analytics.refundRate)} من المتحصل',
          color: palette.negative,
          trend: refunds,
          onTap: analytics.refundedCount == 0
              ? null
              : () => _openLedger(context, status: PaymentStatus.refunded),
          tapHint: analytics.refundedCount == 0
              ? null
              : 'اعرض الحركات المستردة في السجل',
        ),
        DashboardKpiCard(
          emphasized: true,
          icon: Icons.receipt_long_rounded,
          label: 'عدد المعاملات',
          value: FinanceFormat.count(analytics.transactionCount),
          detail: '${FinanceFormat.count(analytics.paidCount)} منها محصّلة',
          color: palette.active,
          trend: transactions,
          onTap: analytics.transactionCount == 0
              ? null
              : () => _openLedger(context),
          tapHint: analytics.transactionCount == 0
              ? null
              : 'اعرض كل حركات الفترة',
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

    return DashboardDonutChart(data: data, valueFormatter: FinanceFormat.money);
  }
}

class _MethodsChart extends StatelessWidget {
  const _MethodsChart({required this.analytics});

  final FinanceAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final rows = analytics.byMethod.where((row) => row.amount > 0).toList();
    final data = [
      for (final (index, row) in rows.indexed)
        ChartDatum(
          label: row.label,
          // A payment rail is a category, not a quantity, so this is the one
          // finance breakdown that keeps the categorical hues. The rankings
          // below are orders and use the sequential ramp instead.
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

    return DashboardDonutChart(data: data, valueFormatter: FinanceFormat.money);
  }
}

/// Two panels side by side on wide screens, stacked below the point where the
/// pair stops fitting — scaled, since what is inside them is Arabic text that
/// grows with the reader.
class _ResponsivePair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsivePair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            MediaQuery.textScalerOf(context).scale(980)) {
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
