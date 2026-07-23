import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'chart_models.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Donut chart with a centred total and a legend showing count + percentage.
class DashboardDonutChart extends StatelessWidget {
  final List<ChartDatum> data;

  const DashboardDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, d) => sum + d.value);
    if (total <= 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'لا توجد بيانات كافية',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return SizedBox(
      height: 196,
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 46,
                    sections: [
                      for (final datum in data)
                        PieChartSectionData(
                          value: datum.value,
                          color: datum.color,
                          radius: 20,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toInt()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'الإجمالي',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: _Legend(data: data, total: total),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<ChartDatum> data;
  final double total;

  const _Legend({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final datum in data)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: datum.color,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      datum.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${datum.value.toInt()}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(datum.value / total * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
