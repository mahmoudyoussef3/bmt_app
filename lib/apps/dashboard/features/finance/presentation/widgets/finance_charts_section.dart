import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_models.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_donut_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_line_chart.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/dashboard_ranked_bars.dart';

import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_state.dart';

/// Real-data finance analytics. The trend comes from `revenue_daily_view`;
/// the breakdowns are derived from the already-loaded payments (no mock data).
/// Each chart renders its own empty state when there is nothing to show.
class FinanceChartsSection extends StatelessWidget {
  final FinanceLoaded state;

  const FinanceChartsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final trend = DashboardPanel(
      icon: Icons.show_chart_rounded,
      title: 'اتجاه الإيرادات اليومي',
      subtitle: 'إجمالي إيرادات الحجوزات حسب اليوم',
      child: DashboardLineChart(data: _trendData(), lineColor: scheme.primary),
    );
    final methods = DashboardPanel(
      icon: Icons.donut_large_rounded,
      title: 'توزيع طرق الدفع',
      subtitle: 'الإيرادات المحققة حسب وسيلة الدفع',
      child: DashboardDonutChart(data: _methodData()),
    );
    final status = DashboardPanel(
      icon: Icons.pie_chart_outline_rounded,
      title: 'المدفوع مقابل المعلق والمسترد',
      subtitle: 'المبالغ حسب حالة الدفع',
      child: DashboardDonutChart(data: _statusData()),
    );
    final routes = DashboardPanel(
      icon: Icons.leaderboard_rounded,
      title: 'أعلى المسارات إيراداً',
      subtitle: 'أعلى ٦ مسارات حسب الإيراد المحقق',
      child: DashboardRankedBars(data: _routeData(scheme)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        return SingleChildScrollView(
          child: Column(
            children: [
              trend,
              const SizedBox(height: AppSpacing.medium),
              if (stacked) ...[
                methods,
                const SizedBox(height: AppSpacing.medium),
                status,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: methods),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: status),
                  ],
                ),
              const SizedBox(height: AppSpacing.medium),
              routes,
            ],
          ),
        );
      },
    );
  }

  List<ChartDatum> _trendData() {
    return [
      for (final point in state.revenueTrend)
        ChartDatum(
          label: '${point.date.day}/${point.date.month}',
          value: point.amount,
          color: const Color(0xFF2563EB),
        ),
    ];
  }

  List<ChartDatum> _methodData() {
    const colors = {
      FinancePaymentMethod.instapay: Color(0xFF6B21A8),
      FinancePaymentMethod.vodafoneCash: Color(0xFFDC2626),
      FinancePaymentMethod.card: Color(0xFF2563EB),
      FinancePaymentMethod.cash: Color(0xFFF59E0B),
    };
    final map = state.revenueByMethod;
    return [
      for (final entry in map.entries)
        if (entry.value > 0)
          ChartDatum(
            label: entry.key.label,
            value: entry.value,
            color: colors[entry.key] ?? const Color(0xFF64748B),
          ),
    ];
  }

  List<ChartDatum> _statusData() {
    const colors = {
      PaymentStatus.success: Color(0xFF16A34A),
      PaymentStatus.pending: Color(0xFFF59E0B),
      PaymentStatus.cancelled: Color(0xFFDC2626),
      PaymentStatus.refunded: Color(0xFF8B5CF6),
    };
    final map = state.amountByStatus;
    return [
      for (final entry in map.entries)
        if (entry.value > 0)
          ChartDatum(
            label: entry.key.label,
            value: entry.value,
            color: colors[entry.key] ?? const Color(0xFF64748B),
          ),
    ];
  }

  List<ChartDatum> _routeData(ColorScheme scheme) {
    return [
      for (final entry in state.revenueByRoute())
        ChartDatum(label: entry.key, value: entry.value, color: scheme.primary),
    ];
  }
}
