import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

import 'chart_models.dart';

/// Smooth line chart for time-series trends (revenue, bookings, subscriptions).
/// [data] is expected in chronological order; only a few x-axis labels are
/// rendered to avoid clutter.
///
/// ## What the console expects of a trend chart
///
/// * **The curve may not invent data.** `isCurved` alone lets fl_chart's spline
///   overshoot a spike — drawing a peak above the highest value that was ever
///   measured, and dipping below zero after it. On a money series that is a
///   figure nobody collected, printed in the office's own console. Overshoot is
///   off and the smoothness is halved.
/// * **A point is readable on hover.** A trend with no tooltip forces the
///   reader to count gridlines; the default fl_chart tooltip is a black pill in
///   a warm-paper console. This one is the console's own panel: surface fill,
///   hairline border, tabular figures, the day above the amount, with a guide
///   line down to the axis.
/// * **A period has a normal.** [showAverage] draws the window's own mean as a
///   dashed reference, which is what turns "some days are higher" into "four
///   days beat the average". It is named in a legend under the plot, not on it:
///   fl_chart anchors a line label to one end of the plot area, and both ends
///   are occupied — the axis figures at one, the series' own last point at the
///   other.
/// * **Numbers are formatted by the caller.** [valueFormatter] writes the axis
///   in the compact ladder a 44px gutter has room for; [tooltipFormatter]
///   writes the bubble, where the whole figure and its unit fit. A chart with
///   one format states it once and the bubble inherits it.
class DashboardLineChart extends StatelessWidget {
  final List<ChartDatum> data;
  final Color? lineColor;

  /// How a value is written on the **axis**. Defaults to the compact
  /// `1.2k` / `3M` ladder every axis in the console reads on.
  final String Function(double value)? valueFormatter;

  /// How a value is written in the **tooltip**, where there is room for the
  /// whole figure and its unit — «5,725 ج.م» rather than «5.7k». Falls back to
  /// [valueFormatter], so a chart that needs no unit states its format once.
  final String Function(double value)? tooltipFormatter;

  /// Draws the series' mean as a dashed reference line. Suppressed for a
  /// series too short for a mean to describe anything.
  final bool showAverage;

  /// What the reference line is called, e.g. «المتوسط». Only drawn with
  /// [showAverage].
  final String averageLabel;

  final double height;

  const DashboardLineChart({
    super.key,
    required this.data,
    this.lineColor,
    this.valueFormatter,
    this.tooltipFormatter,
    this.showAverage = true,
    this.averageLabel = 'المتوسط',
    this.height = 196,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (data.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'لا توجد بيانات كافية',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
      );
    }
    final color = lineColor ?? scheme.primary;
    final format = valueFormatter ?? _axisLabel;
    final tooltipFormat = tooltipFormatter ?? format;
    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final average =
        data.fold<double>(0, (sum, d) => sum + d.value) / data.length;

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
    final drawAverage = showAverage && data.length >= 4 && average > 0;

    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: DashboardColors.faintInk(context),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: DashboardColors.divider(context),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (drawAverage)
                      HorizontalLine(
                        y: average,
                        color: DashboardColors.faintInk(context),
                        strokeWidth: 1,
                        dashArray: const [3, 4],
                      ),
                  ],
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
                      interval: step,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) =>
                          Text(format(value), style: axisStyle),
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
                          child: Text(data[index].label, style: axisStyle),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (barData, indexes) => [
                    for (final _ in indexes)
                      TouchedSpotIndicatorData(
                        FlLine(
                          color: color.withValues(alpha: 0.45),
                          strokeWidth: 1,
                          dashArray: const [3, 3],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: DashboardColors.panel(context),
                              ),
                        ),
                      ),
                  ],
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => DashboardColors.panel(context),
                    tooltipBorder: BorderSide(
                      color: DashboardColors.borderStrong(context),
                    ),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          tooltipFormat(spot.y),
                          theme.textTheme.labelLarge!.copyWith(
                            color: DashboardColors.ink(context),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          children: [
                            TextSpan(
                              text: '\n${_labelAt(spot.x)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DashboardColors.mutedInk(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          textAlign: TextAlign.start,
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i].value),
                    ],
                    isCurved: true,
                    // Half the default smoothing, and no overshoot: a spline that
                    // rounds past a spike draws a value the office never collected.
                    curveSmoothness: 0.22,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2.6,
                    isStrokeCapRound: true,
                    // Only the newest point carries a dot — the "you are here" mark
                    // at the end of the line. A dot on all thirty is a bead curtain.
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) =>
                          spot.x == (data.length - 1).toDouble(),
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3.2,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: DashboardColors.panel(context),
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.24),
                          color.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (drawAverage)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _AverageLegend(
              label: averageLabel,
              reading: tooltipFormat(average),
              color: DashboardColors.faintInk(context),
            ),
          ),
      ],
    );
  }

  String _labelAt(double x) {
    final index = x.round();
    if (index < 0 || index >= data.length) return '';
    return data[index].label;
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

/// The dashed reference line, named under the plot rather than on it.
///
/// fl_chart can print a label against a `HorizontalLine`, but it anchors to one
/// end of the plot area — where the axis gutter is at one edge and the series
/// itself is at the other — so on a real series it landed either on top of the
/// axis figures or across the curve. A legend under the chart is readable at
/// every window width and never covers a data point.
class _AverageLegend extends StatelessWidget {
  const _AverageLegend({
    required this.label,
    required this.reading,
    required this.color,
  });

  final String label;
  final String reading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(16, 1),
          painter: _DashPainter(color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $reading',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + 3).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
