import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_bar_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/finance_analytics.dart';
import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_state.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// The "why" behind the overview: rhythm, momentum, concentration, and an
/// explicit like-for-like comparison against the previous window.
class FinanceAnalyticsTab extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceAnalyticsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final analytics = state.analytics;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SignalsPanel(analytics: analytics),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeCumulativeRevenue,
          icon: Icons.stacked_line_chart_rounded,
          title: 'الإيراد التراكمي',
          subtitle: 'كيف تراكم صافي الإيراد يوماً بعد يوم خلال الفترة',
          child: DashboardLineChart(
            data: [
              for (final point in analytics.cumulativeDaily)
                ChartDatum(
                  label: FinanceFormat.shortDate(point.date),
                  value: point.net,
                  color: palette.positive,
                ),
            ],
            lineColor: palette.positive,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeWeekdayPerformance,
          icon: Icons.calendar_view_week_rounded,
          title: 'أداء أيام الأسبوع',
          subtitle: 'أي أيام الأسبوع تحقق أعلى تحصيل خلال هذه الفترة',
          child: DashboardBarChart(
            data: [
              for (final row in analytics.byWeekday)
                ChartDatum(
                  label: row.label,
                  value: row.amount,
                  color: palette.active,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeDailyVolume,
          icon: Icons.bar_chart_rounded,
          title: 'عدد المعاملات اليومي',
          subtitle: 'حجم الحركة اليومي — عدد العمليات وليس قيمتها',
          child: DashboardBarChart(
            data: [
              for (final point in _recentDaily(analytics))
                ChartDatum(
                  label: FinanceFormat.shortDate(point.date),
                  value: point.transactions.toDouble(),
                  color: palette.accent,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financePeriodComparison,
          icon: Icons.compare_arrows_rounded,
          title: 'مقارنة بالفترة السابقة',
          subtitle: analytics.hasComparison
              ? 'مقارنة كل مؤشر بفترة مساوية في الطول تسبقها مباشرة'
              : 'اختر فترة محددة لتفعيل المقارنة',
          child: _ComparisonTable(analytics: analytics),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          sectionId: DashboardSectionIds.financeStatusMix,
          icon: Icons.query_stats_rounded,
          title: 'توزيع الحركات حسب الحالة',
          subtitle: 'أين تقف أموال الفترة: محصّلة، معلقة، ملغاة أو مستردة',
          child: FinanceRankedList(
            rows: analytics.byStatus,
            total: analytics.byStatus.fold(0.0, (sum, row) => sum + row.amount),
            limit: PaymentStatus.values.length,
          ),
        ),
      ],
    );
  }

  /// A 90-day bar chart is unreadable; the volume chart shows the last 30 days
  /// of whatever window is selected.
  List<FinanceDailyPoint> _recentDaily(FinanceAnalytics analytics) {
    const maxBars = 30;
    final daily = analytics.daily;
    if (daily.length <= maxBars) return daily;
    return daily.sublist(daily.length - maxBars);
  }
}

/// Headline diagnostics an owner would otherwise have to work out by hand.
class _SignalsPanel extends StatelessWidget {
  final FinanceAnalytics analytics;

  const _SignalsPanel({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final best = analytics.bestDay;
    final busiest = analytics.busiestDay;
    final topRoute = analytics.byRoute.isEmpty ? null : analytics.byRoute.first;

    return DashboardPanel(
      sectionId: DashboardSectionIds.financeKpis,
      icon: Icons.insights_rounded,
      title: 'مؤشرات الأداء',
      subtitle: 'قراءة سريعة لسلوك الإيراد خلال ${analytics.period.label}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1040
              ? 3
              : constraints.maxWidth >= 620
              ? 2
              : 1;

          final signals = <Widget>[
            _SignalTile(
              icon: Icons.trending_up_rounded,
              label: 'متوسط الإيراد اليومي',
              value: FinanceFormat.money(analytics.averageDailyRevenue),
              detail:
                  '${FinanceFormat.count(analytics.activeDays)} يوم فيه تحصيل من ${FinanceFormat.count(analytics.daily.length)}',
              color: palette.active,
            ),
            _SignalTile(
              icon: Icons.emoji_events_outlined,
              label: 'أفضل يوم',
              value: best == null ? '—' : FinanceFormat.money(best.net),
              detail: best == null
                  ? 'لا توجد بيانات'
                  : FinanceFormat.date(best.date),
              color: palette.positive,
            ),
            _SignalTile(
              icon: Icons.local_fire_department_outlined,
              label: 'أكثر يوم حركة',
              value: busiest == null
                  ? '—'
                  : '${FinanceFormat.count(busiest.transactions)} عملية',
              detail: busiest == null
                  ? 'لا توجد بيانات'
                  : FinanceFormat.date(busiest.date),
              color: palette.warning,
            ),
            _SignalTile(
              icon: Icons.hub_outlined,
              label: 'تركّز الإيراد',
              value: FinanceFormat.percent(analytics.routeConcentration),
              detail: topRoute == null
                  ? 'لا توجد مسارات في الفترة'
                  : 'من مسار ${topRoute.label} وحده',
              color: palette.accent,
            ),
            _SignalTile(
              icon: Icons.undo_rounded,
              label: 'معدل الاسترداد',
              value: FinanceFormat.percent(analytics.refundRate),
              detail:
                  '${FinanceFormat.count(analytics.refundedCount)} عملية مستردة',
              color: palette.negative,
            ),
            _SignalTile(
              icon: Icons.savings_outlined,
              label: 'معدل التحصيل',
              value: FinanceFormat.percent(analytics.collectionRate),
              detail:
                  'متبقٍ ${FinanceFormat.money(analytics.pending)} قيد التحصيل',
              color: palette.positive,
            ),
          ];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: signals.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.small,
              mainAxisSpacing: AppSpacing.small,
              mainAxisExtent: 96,
            ),
            itemBuilder: (context, index) => signals[index],
          );
        },
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _SignalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final FinanceAnalytics analytics;

  const _ComparisonTable({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final previous = analytics.previous;
    final scheme = Theme.of(context).colorScheme;

    if (previous == null) {
      return Text(
        'الفترة "${analytics.period.label}" تشمل كل السجلات، فلا توجد فترة سابقة مساوية لمقارنتها بها.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final rows = <(String, String, String, double?, bool)>[
      (
        'صافي الإيراد',
        FinanceFormat.money(analytics.netRevenue),
        FinanceFormat.money(previous.netRevenue),
        analytics.netRevenueChange,
        false,
      ),
      (
        'إجمالي المتحصلات',
        FinanceFormat.money(analytics.grossReceived),
        FinanceFormat.money(previous.grossReceived),
        analytics.grossReceivedChange,
        false,
      ),
      (
        'عدد المعاملات',
        FinanceFormat.count(analytics.transactionCount),
        FinanceFormat.count(previous.transactionCount),
        analytics.transactionsChange,
        false,
      ),
      (
        'متوسط قيمة المعاملة',
        FinanceFormat.money(analytics.averageTicket),
        FinanceFormat.money(previous.averageTicket),
        analytics.averageTicketChange,
        false,
      ),
      (
        'المرتجعات',
        FinanceFormat.money(analytics.refunded),
        FinanceFormat.money(previous.refunded),
        analytics.refundedChange,
        true,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Row(
            children: [
              Expanded(flex: 3, child: _head(context, 'المؤشر')),
              Expanded(flex: 2, child: _head(context, 'الفترة الحالية')),
              Expanded(flex: 2, child: _head(context, 'الفترة السابقة')),
              Expanded(flex: 2, child: _head(context, 'التغير')),
            ],
          ),
        ),
        for (final (label, current, before, change, inverted) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    current,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    before,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FinanceDeltaBadge(
                      change: change,
                      inverted: inverted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _head(BuildContext context, String label) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
