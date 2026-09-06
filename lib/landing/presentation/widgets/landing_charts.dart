import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import 'landing_motion.dart';

/// The page's charts, painted in the design file's own SVG coordinate space.
///
/// Every chart here is decorative product-shot data, not a live feed, so it is
/// painted rather than driven through `fl_chart`: the design specifies exact
/// geometry (grid rules at y=24/58/92, a baseline at y=114, 26px bars on a
/// 46px pitch) and reproducing that through a charting library's layout engine
/// would be approximation dressed up as configuration. Each painter draws in
/// the source `viewBox` units and the canvas is scaled to fit, so the result
/// matches the design at any width.
class _SvgScale {
  const _SvgScale(this.canvas, this.size, this.viewBox);

  final Canvas canvas;
  final Size size;
  final Size viewBox;

  double get k => size.width / viewBox.width;

  void apply() => canvas.scale(k);
}

void _paintGrid(
  Canvas canvas,
  double width,
  List<double> rules,
  double baseline,
) {
  final soft = Paint()
    ..color = LandingPalette.borderSoft
    ..strokeWidth = 1;
  for (final y in rules) {
    canvas.drawLine(Offset(0, y), Offset(width, y), soft);
  }
  canvas.drawLine(
    Offset(0, baseline),
    Offset(width, baseline),
    Paint()
      ..color = LandingPalette.border
      ..strokeWidth = 1,
  );
}

/// The day and month names under a chart's baseline.
///
/// [baselineY] is the design's own `<text y="...">`, which in SVG is the
/// **baseline** — not the bottom of the line box. Positioning by box bottom
/// works with a compact face and fails with Cairo, whose line box is 1.874em:
/// the labels ride up over the bars. So the box is offset by its measured
/// baseline instead.
///
/// The label is laid out in design units and left in the already-scaled
/// canvas, exactly as the SVG's `font-size="10"` scales with its viewBox.
void _paintAxisLabels(
  Canvas canvas,
  List<String> labels,
  List<double> centres,
  double baselineY,
) {
  for (var i = 0; i < labels.length && i < centres.length; i++) {
    final painter = TextPainter(
      text: TextSpan(
        text: labels[i],
        style: LandingType.label(10, color: LandingPalette.faint),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(
      canvas,
      Offset(centres[i] - painter.width / 2, baselineY - baseline),
    );
  }
}

/// The hero's weekly-bookings column chart (viewBox 340×130).
class LandingBarChart extends StatelessWidget {
  const LandingBarChart({
    super.key,
    required this.heights,
    required this.labels,
    this.barColor = LandingPalette.brand,
    this.opacity = 0.85,
  });

  /// Bar heights in the design's own units, measured up from the baseline.
  final List<double> heights;
  final List<String> labels;
  final Color barColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 340 / 130,
      // The columns grow out of the baseline once the card arrives; the grid
      // and the axis labels are the chart's furniture and stay put.
      child: LandingRevealBuilder(
        builder: (context, t) => CustomPaint(
          painter: _BarChartPainter(
            heights: heights,
            labels: labels,
            barColor: barColor.withValues(alpha: opacity),
            grow: t,
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.heights,
    required this.labels,
    required this.barColor,
    required this.grow,
  });

  final List<double> heights;
  final List<String> labels;
  final Color barColor;

  /// 0 → 1: how far each column has risen from the baseline.
  final double grow;

  static const _viewBox = Size(340, 130);
  static const _baseline = 114.0;
  static const _barWidth = 26.0;
  static const _pitch = 46.0;
  static const _firstX = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _SvgScale(canvas, size, _viewBox).apply();

    _paintGrid(canvas, _viewBox.width, const [24, 58, 92], _baseline);

    final fill = Paint()..color = barColor;
    final centres = <double>[];
    for (var i = 0; i < heights.length; i++) {
      final x = _firstX + _pitch * i;
      final height = heights[i] * grow;
      centres.add(x + _barWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, _baseline - height, _barWidth, height),
          const Radius.circular(6),
        ),
        fill,
      );
    }

    _paintAxisLabels(canvas, labels, centres, 127);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.heights != heights || old.barColor != barColor || old.grow != grow;
}

/// The dashboard section's trend chart — a filled area under a 2.6px line
/// (viewBox 420×160). Points are given in design units.
class LandingLineChart extends StatelessWidget {
  const LandingLineChart({super.key, required this.points});

  final List<Offset> points;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 420 / 160,
      // Keyed on the series: the chart is swapped when the operator changes
      // tab, and a new key restarts the draw, so the swap eases in exactly as
      // the first arrival did rather than cutting.
      child: LandingRevealBuilder(
        key: ValueKey(points),
        duration: const Duration(milliseconds: 520),
        builder: (context, t) => CustomPaint(
          painter: _LineChartPainter(points: points, reveal: t),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points, required this.reveal});

  final List<Offset> points;
  final double reveal;

  static const _viewBox = Size(420, 160);
  static const _baseline = 132.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _SvgScale(canvas, size, _viewBox).apply();

    _paintGrid(canvas, _viewBox.width, const [24, 60, 96], _baseline);
    if (points.length < 2) {
      canvas.restore();
      return;
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, _baseline)
      ..lineTo(points.first.dx, _baseline)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LandingPalette.brand.withValues(alpha: 0.20 * reveal),
            LandingPalette.brand.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, _viewBox.width, _baseline)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = LandingPalette.brand.withValues(alpha: reveal)
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points || old.reveal != reveal;
}

/// Revenue against expenses — a solid brand line, a dashed warn line and
/// three emphasis dots (viewBox 420×170).
class LandingDualLineChart extends StatelessWidget {
  const LandingDualLineChart({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.markers,
  });

  final List<Offset> revenue;
  final List<Offset> expenses;
  final List<Offset> markers;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 420 / 170,
      child: LandingRevealBuilder(
        builder: (context, t) => CustomPaint(
          painter: _DualLinePainter(
            revenue: revenue,
            expenses: expenses,
            markers: markers,
            draw: t,
          ),
        ),
      ),
    );
  }
}

class _DualLinePainter extends CustomPainter {
  _DualLinePainter({
    required this.revenue,
    required this.expenses,
    required this.markers,
    required this.draw,
  });

  final List<Offset> revenue;
  final List<Offset> expenses;
  final List<Offset> markers;

  /// 0 → 1: how much of each series has been drawn. The two lines are drawn
  /// left to right in step, and the emphasis dots land in the last third,
  /// each as its own point is reached.
  final double draw;

  static const _viewBox = Size(420, 170);
  static const _baseline = 134.0;

  Path _path(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// `stroke-dasharray: 6 5` has no Flutter equivalent on [Canvas.drawPath],
  /// so the dashed series is walked segment by segment.
  /// The head of [source] — the first [draw] of its length.
  Path _drawn(Path source) {
    if (draw >= 1) return source;
    final result = Path();
    for (final metric in source.computeMetrics()) {
      result.addPath(
        metric.extractPath(0, metric.length * draw.clamp(0.0, 1.0)),
        Offset.zero,
      );
    }
    return result;
  }

  Path _dashed(Path source, double dash, double gap) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        result.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next + gap;
      }
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _SvgScale(canvas, size, _viewBox).apply();

    _paintGrid(canvas, _viewBox.width, const [20, 58, 96], _baseline);

    canvas.drawPath(
      _drawn(_path(revenue)),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = LandingPalette.brand
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      _dashed(_drawn(_path(expenses)), 6, 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = LandingPalette.warn
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = LandingPalette.brand;
    for (var i = 0; i < markers.length; i++) {
      // A dot appears when the line has reached its x, measured across the
      // series' own span rather than the viewBox, so the last one lands with
      // the end of the stroke.
      final span = revenue.last.dx - revenue.first.dx;
      final reached =
          span <= 0 || (markers[i].dx - revenue.first.dx) / span <= draw;
      if (!reached) continue;
      canvas.drawCircle(markers[i], i == markers.length - 1 ? 3.8 : 3, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DualLinePainter old) =>
      old.revenue != revenue || old.draw != draw;
}

/// The analytics card's revenue-by-period columns (viewBox 260×130).
class LandingPeriodBars extends StatelessWidget {
  const LandingPeriodBars({
    super.key,
    required this.heights,
    required this.labels,
  });

  final List<double> heights;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 260 / 130,
      child: LandingRevealBuilder(
        builder: (context, t) => CustomPaint(
          painter: _PeriodBarsPainter(
            heights: heights,
            labels: labels,
            grow: t,
          ),
        ),
      ),
    );
  }
}

class _PeriodBarsPainter extends CustomPainter {
  _PeriodBarsPainter({
    required this.heights,
    required this.labels,
    required this.grow,
  });

  final List<double> heights;
  final List<String> labels;

  /// 0 → 1: how far each column has risen from the baseline.
  final double grow;

  static const _viewBox = Size(260, 130);
  static const _baseline = 112.0;
  static const _barWidth = 30.0;
  static const _pitch = 58.0;
  static const _firstX = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _SvgScale(canvas, size, _viewBox).apply();

    _paintGrid(canvas, _viewBox.width, const [22, 56, 90], _baseline);

    final fill = Paint()..color = LandingPalette.navy.withValues(alpha: 0.85);
    final centres = <double>[];
    for (var i = 0; i < heights.length; i++) {
      final x = _firstX + _pitch * i;
      final height = heights[i] * grow;
      centres.add(x + _barWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, _baseline - height, _barWidth, height),
          const Radius.circular(6),
        ),
        fill,
      );
    }

    _paintAxisLabels(canvas, labels, centres, 126);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeriodBarsPainter old) =>
      old.heights != heights || old.grow != grow;
}

/// The occupancy gauge — a 14px ring, opened at the top, with the figure
/// centred inside it.
class LandingDonut extends StatelessWidget {
  const LandingDonut({
    super.key,
    required this.fraction,
    required this.value,
    required this.caption,
    this.diameter = 150,
  });

  final double fraction;
  final String value;
  final String caption;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: LandingRevealBuilder(
        builder: (context, t) => CustomPaint(
          painter: _DonutPainter(fraction: fraction * t),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: LandingType.metric(28)),
                const SizedBox(height: 2),
                Text(caption, style: LandingType.label(11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    // The design's ring is r=48 with a 14px stroke inside a 120 box.
    final k = size.width / 120;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = 48 * k;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * k
        ..color = LandingPalette.well,
    );

    canvas.drawArc(
      rect,
      -1.5707963267948966,
      6.283185307179586 * fraction.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * k
        ..strokeCap = StrokeCap.round
        ..color = LandingPalette.brand,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fraction != fraction;
}

/// The faint dashboard wireframe behind the closing CTA band.
class LandingWireframe extends StatelessWidget {
  const LandingWireframe({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 420 / 240,
      child: CustomPaint(painter: _WireframePainter()),
    );
  }
}

class _WireframePainter extends CustomPainter {
  static const _viewBox = Size(420, 240);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _SvgScale(canvas, size, _viewBox).apply();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 400, 220),
        const Radius.circular(14),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    void block(double x, double y, double w, double h, double r, double a) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    block(30, 34, 110, 54, 8, 0.50);
    block(152, 34, 110, 54, 8, 0.35);
    block(274, 34, 110, 54, 8, 0.25);
    block(30, 104, 354, 14, 7, 0.30);
    block(30, 130, 300, 14, 7, 0.22);
    block(30, 156, 330, 14, 7, 0.18);
    block(30, 182, 260, 14, 7, 0.14);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WireframePainter oldDelegate) => false;
}
