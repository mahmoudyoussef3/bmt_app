import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// Real-data subscription analytics computed from the loaded subscriptions
/// list (status mix, revenue trend by month, subscribers per plan).
class SubscriptionsAnalytics extends StatelessWidget {
  final List<UserSubscription> subscriptions;

  const SubscriptionsAnalytics({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);

    final status = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'حالة الاشتراكات',
      subtitle: 'نشط مقابل منتهٍ وملغي',
      child: DashboardDonutChart(data: _statusData(palette)),
    );
    final trend = DashboardPanel(
      icon: Icons.show_chart_rounded,
      title: 'اتجاه إيراد الاشتراكات',
      subtitle: 'إجمالي قيمة الاشتراكات حسب الشهر',
      child: DashboardLineChart(
        data: _revenueTrend(palette),
        lineColor: scheme.primary,
      ),
    );
    final plans = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'المشتركون حسب الباقة',
      subtitle: 'أعلى الباقات حسب عدد المشتركين',
      child: DashboardRankedBars(data: _byPlan(scheme)),
    );
    final routes = DashboardPanel(
      icon: Icons.alt_route_rounded,
      title: 'المشتركون حسب خط السير',
      subtitle: 'أكثر خطوط السير طلبًا للاشتراك',
      child: DashboardRankedBars(data: _byRoute(scheme)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              status,
              const SizedBox(height: AppSpacing.medium),
              trend,
              const SizedBox(height: AppSpacing.medium),
              plans,
              const SizedBox(height: AppSpacing.medium),
              routes,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: status),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: trend),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: plans),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: routes),
              ],
            ),
          ],
        );
      },
    );
  }

  List<ChartDatum> _statusData(DashboardChartPalette palette) {
    final colors = {
      SubscriptionStatus.active: palette.positive,
      SubscriptionStatus.pendingPayment: palette.warning,
      SubscriptionStatus.expired: palette.neutral,
      SubscriptionStatus.cancelled: palette.negative,
    };
    final counts = <SubscriptionStatus, int>{};
    for (final s in subscriptions) {
      counts[s.status] = (counts[s.status] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        ChartDatum(
          label: entry.key.label,
          value: entry.value.toDouble(),
          color: colors[entry.key] ?? palette.neutral,
        ),
    ];
  }

  List<ChartDatum> _revenueTrend(DashboardChartPalette palette) {
    final byMonth = <String, double>{};
    final sorted = [...subscriptions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final s in sorted) {
      final key = '${s.createdAt.year}/${s.createdAt.month}';
      byMonth[key] = (byMonth[key] ?? 0) + s.price;
    }
    return [
      for (final entry in byMonth.entries)
        ChartDatum(label: entry.key, value: entry.value, color: palette.active),
    ];
  }

  List<ChartDatum> _byPlan(ColorScheme scheme) {
    final counts = <String, int>{};
    for (final s in subscriptions) {
      counts[s.packageName] = (counts[s.packageName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in sorted.take(6))
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: scheme.primary,
        ),
    ];
  }

  List<ChartDatum> _byRoute(ColorScheme scheme) {
    final counts = <String, int>{};
    for (final s in subscriptions) {
      if (s.routeLabel.isEmpty) continue;
      counts[s.routeLabel] = (counts[s.routeLabel] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in sorted.take(6))
        ChartDatum(
          label: entry.key,
          value: entry.value.toDouble(),
          color: scheme.tertiary,
        ),
    ];
  }
}
