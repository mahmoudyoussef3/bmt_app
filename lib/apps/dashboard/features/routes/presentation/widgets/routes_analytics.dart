import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';

/// Real-data analytics for the routes workspace, computed from the loaded
/// routes (no extra fetch, no mock data).
class RoutesAnalytics extends StatelessWidget {
  final RoutesLoaded state;

  const RoutesAnalytics({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final donut = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'توزيع حالات المسارات',
      subtitle: 'كل المسارات حسب الحالة',
      child: DashboardDonutChart(data: _statusData(context)),
    );
    final ranked = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'أكبر المسارات بعدد المحطات',
      subtitle: 'أعلى ٥ مسارات حسب عدد المحطات',
      child: DashboardRankedBars(data: _topRoutes(scheme)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              donut,
              const SizedBox(height: AppSpacing.medium),
              ranked,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: donut),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: ranked),
          ],
        );
      },
    );
  }

  List<ChartDatum> _statusData(BuildContext context) {
    final counts = <OperationRouteStatus, int>{};
    for (final route in state.routes) {
      counts[route.status] = (counts[route.status] ?? 0) + 1;
    }
    return [
      for (final status in OperationRouteStatus.values)
        if ((counts[status] ?? 0) > 0)
          ChartDatum(
            label: status.label,
            value: counts[status]!.toDouble(),
            color: _routeStatusColor(context, status),
          ),
    ];
  }

  List<ChartDatum> _topRoutes(ColorScheme scheme) {
    final sorted = [...state.routes]
      ..sort((a, b) => b.stations.length.compareTo(a.stations.length));
    return [
      for (final route in sorted.take(5))
        ChartDatum(
          label: route.name,
          value: route.stations.length.toDouble(),
          color: scheme.primary,
        ),
    ];
  }
}

Color _routeStatusColor(BuildContext context, OperationRouteStatus status) {
  final palette = DashboardChartPalette.of(context);
  return switch (status) {
    OperationRouteStatus.active => palette.positive,
    OperationRouteStatus.paused => palette.warning,
    OperationRouteStatus.draft => palette.active,
    OperationRouteStatus.archived => palette.negative,
  };
}
