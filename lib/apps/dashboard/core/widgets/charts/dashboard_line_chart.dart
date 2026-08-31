import 'dart:math' as math;

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

    // A rounded axis, not `peak × 1.2`. An arbitrary ceiling makes fl_chart
    // choose its own tick positions, and on a money series that produced two
    // gridlines a hair apart — 2,952 and 3,000 — both of which the "k"
    // formatter below printed as "3k", one directly above the other. Rounding
    // the *step* first and taking the ceiling from it gives ticks that are
    // whole numbers and can never collide.
    final step = _niceStep((maxValue <= 0 ? 1 : maxValue) / 4);
    final maxY =
        step * math.max(2, ((maxValue <= 0 ? 1 : maxValue) / step).ceil());
    final labelStep = (data.length / 4).ceil().clamp(1, data.length);

    return SizedBox(
      height: 196,
      // fl_chart centres an axis label on its gridline, so the topmost one
      // loses its upper half to the edge of the box. The headroom is cheaper
      // than a taller chart.
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: step,
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
                  interval: step,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    _axisLabel(value),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  // One tick per data point. Without it fl_chart chooses its own
                  // spacing from the axis range, which on a wide chart lands on
                  // fractional positions — 3.0 and 3.5 both floor to index 3 —
                  // and the same date is drawn twice side by side. Thinning is
                  // `labelStep`'s job below; this only makes the ticks line up
                  // with the points they name.
                  interval: 1,
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
      ),
    );
  }

  /// A rounded gridline step at or above [raw] — 1, 2, 2.5 or 5 times a power
  /// of ten, the ladder every axis in the console reads on.
  static double _niceStep(double raw) {
    if (raw <= 0 || !raw.isFinite) return 1;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalised = raw / magnitude;
    final step = normalised <= 1
        ? 1.0
        : normalised <= 2
        ? 2.0
        : normalised <= 2.5
        ? 2.5
        : normalised <= 5
        ? 5.0
        : 10.0;
    return step * magnitude;
  }

  static String _axisLabel(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) {
      final thousands = value / 1000;
      return thousands == thousands.roundToDouble()
          ? '${thousands.round()}k'
          : '${thousands.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }
}
