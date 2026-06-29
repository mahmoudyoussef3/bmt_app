import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/user_subscription.dart';

/// Real-data subscription analytics computed from the loaded subscriptions
/// list (status mix, revenue trend by month, subscribers per plan).
class SubscriptionsAnalytics extends StatelessWidget {
  final List<UserSubscription> subscriptions;

  const SubscriptionsAnalytics({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final status = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'حالة الاشتراكات',
      subtitle: 'نشط مقابل منتهٍ وملغي',
      child: DashboardDonutChart(data: _statusData()),
    );
    final trend = DashboardPanel(
      icon: Icons.show_chart_rounded,
      title: 'اتجاه إيراد الاشتراكات',
      subtitle: 'إجمالي قيمة الاشتراكات حسب الشهر',
      child: DashboardLineChart(
        data: _revenueTrend(),
        lineColor: scheme.primary,
      ),
    );
    final plans = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'المشتركون حسب الباقة',
      subtitle: 'أعلى الباقات حسب عدد المشتركين',
      child: DashboardRankedBars(data: _byPlan(scheme)),
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
            plans,
          ],
        );
      },
    );
  }

  List<ChartDatum> _statusData() {
    const colors = {
      SubscriptionStatus.active: Color(0xFF16A34A),
      SubscriptionStatus.pendingPayment: Color(0xFFF59E0B),
      SubscriptionStatus.expired: Color(0xFF64748B),
      SubscriptionStatus.cancelled: Color(0xFFDC2626),
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
          color: colors[entry.key] ?? const Color(0xFF64748B),
        ),
    ];
  }

  List<ChartDatum> _revenueTrend() {
    final byMonth = <String, double>{};
    final sorted = [...subscriptions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final s in sorted) {
      final key = '${s.createdAt.year}/${s.createdAt.month}';
      byMonth[key] = (byMonth[key] ?? 0) + s.price;
    }
    return [
      for (final entry in byMonth.entries)
        ChartDatum(
          label: entry.key,
          value: entry.value,
          color: const Color(0xFF2563EB),
        ),
    ];
  }

  List<ChartDatum> _byPlan(ColorScheme scheme) {
    final counts = <String, int>{};
    for (final s in subscriptions) {
      counts[s.routeName] = (counts[s.routeName] ?? 0) + 1;
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
}
