import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/owner_overview.dart';

class OwnerOverviewCharts extends StatelessWidget {
  final OwnerOverview overview;

  const OwnerOverviewCharts({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final trend = DashboardPanel(
      icon: Icons.show_chart_rounded,
      title: 'اتجاه الإيرادات',
      subtitle: 'إجمالي إيرادات الحجوزات حسب اليوم',
      child: DashboardLineChart(data: _trendData(), lineColor: scheme.primary),
    );
    final clients = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'حالة العملاء المشتركين',
      subtitle: 'نشط مقابل منتهٍ وملغي',
      child: DashboardDonutChart(data: _clientsData()),
    );
    final plans = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'العملاء حسب الباقة',
      subtitle: 'أعلى الباقات حسب عدد المشتركين',
      child: DashboardRankedBars(data: _plansData(scheme)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              trend,
              const SizedBox(height: AppSpacing.medium),
              clients,
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
                Expanded(child: trend),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: clients),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            plans,
          ],
        );
      },
    );
  }

  List<ChartDatum> _trendData() {
    return [
      for (final p in overview.revenueTrend)
        ChartDatum(
          label: '${p.date.day}/${p.date.month}',
          value: p.amount,
          color: const Color(0xFF2563EB),
        ),
    ];
  }

  List<ChartDatum> _clientsData() {
    return [
      if (overview.activeClients > 0)
        ChartDatum(
          label: 'نشط',
          value: overview.activeClients.toDouble(),
          color: const Color(0xFF16A34A),
        ),
      if (overview.expiredClients > 0)
        ChartDatum(
          label: 'منتهٍ',
          value: overview.expiredClients.toDouble(),
          color: const Color(0xFF64748B),
        ),
      if (overview.cancelledClients > 0)
        ChartDatum(
          label: 'ملغي',
          value: overview.cancelledClients.toDouble(),
          color: const Color(0xFFDC2626),
        ),
    ];
  }

  List<ChartDatum> _plansData(ColorScheme scheme) {
    return [
      for (final stat in overview.byPlan.take(6))
        ChartDatum(
          label: stat.plan,
          value: stat.clients.toDouble(),
          color: scheme.primary,
        ),
    ];
  }
}
