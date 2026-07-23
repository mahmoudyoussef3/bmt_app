import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';

import '../cubit/tickets_state.dart';

/// Support desk headline numbers.
///
/// Uses the shared KPI grid rather than a fixed four-column [Row]: the old
/// layout squeezed all four tiles onto one line at any width, clipping their
/// labels on narrow screens.
class SummaryStats extends StatelessWidget {
  final TicketsLoaded state;

  const SummaryStats({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return DashboardKpiGrid(
      children: [
        DashboardKpiCard(
          label: 'تذاكر جديدة',
          value: '${state.newCount}',
          icon: Icons.mark_email_unread_outlined,
          color: DashboardChartPalette.active,
        ),
        DashboardKpiCard(
          label: 'قيد المراجعة',
          value: '${state.underReviewCount}',
          icon: Icons.pending_actions_outlined,
          color: DashboardChartPalette.warning,
        ),
        DashboardKpiCard(
          label: 'تم الحل',
          value: '${state.resolvedCount}',
          icon: Icons.check_circle_outline_rounded,
          color: DashboardChartPalette.positive,
        ),
        DashboardKpiCard(
          label: 'متأخرة',
          detail: 'أكثر من ٢٤ ساعة بلا حل',
          value: '${state.delayedCount}',
          icon: Icons.running_with_errors_outlined,
          color: state.delayedCount > 0
              ? DashboardChartPalette.negative
              : DashboardChartPalette.neutral,
        ),
      ],
    );
  }
}
