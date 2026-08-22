import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'chart_models.dart';

/// Vertical bar chart with short category labels on the x-axis.
class DashboardBarChart extends StatelessWidget {
  final List<ChartDatum> data;

  const DashboardBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);
    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final maxY = (maxValue <= 0 ? 1 : maxValue) * 1.25;
    return SizedBox(
      height: 196,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: scheme.outline.withAlpha(40), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          // Always-on value labels: rendered via the touch tooltip API with
          // touch disabled and every rod pre-marked as "showing", the
          // documented fl_chart way to get a permanent label rather than one
          // that only appears on tap.
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(rod.toY.toInt().toString(), labelStyle!),
            ),
          ),
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
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                showingTooltipIndicators: const [0],
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    color: data[i].color,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
