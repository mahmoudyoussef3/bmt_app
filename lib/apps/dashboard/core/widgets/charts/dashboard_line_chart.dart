import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'chart_models.dart';

/// Smooth line chart for time-series trends (revenue, bookings, subscriptions).
/// [data] is expected in chronological order; only a few x-axis labels are
/// rendered to avoid clutter.
class DashboardLineChart extends StatelessWidget {
  final List<ChartDatum> data;
  final Color? lineColor;

  const DashboardLineChart({super.key, required this.data, this.lineColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.length < 2) {
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
    final color = lineColor ?? scheme.primary;
    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final maxY = (maxValue <= 0 ? 1 : maxValue) * 1.2;
    final labelStep = (data.length / 4).ceil().clamp(1, data.length);

    return SizedBox(
      height: 196,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: scheme.outline.withAlpha(40), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  value >= 1000
                      ? '${(value / 1000).toStringAsFixed(0)}k'
                      : value.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 ||
                      index >= data.length ||
                      index % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[index].label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].value),
              ],
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
