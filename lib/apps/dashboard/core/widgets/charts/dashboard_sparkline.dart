import 'package:flutter/material.dart';

/// A wordless line: shape only, no axes, no labels, no ticks.
///
/// The companion to [DashboardLineChart] rather than a smaller copy of it. A
/// chart answers "what were the numbers?"; a sparkline answers "which way is
/// this going?" beside the number that is already on screen. That is why it is
/// hand-painted instead of a shrunken `fl_chart`: at 28 logical pixels every
/// axis, grid line and tooltip is either invisible or noise, and ten of these
/// render on one KPI grid.
///
/// Scaled to its own minimum and maximum, not to zero. A week of revenue
/// between 4,800 and 5,200 is a flat line against a zero baseline and a
/// readable wobble against its own range — and the wobble is the entire
/// question a sparkline is asked. The value itself is always printed beside it,
/// so the missing baseline cannot mislead.
///
/// ## What the drawing carries
///
/// * **A smoothed path**, Catmull-Rom with its control points clamped to each
///   segment's own range. Straight segments made a seven-point week read as a
///   seismograph; an unclamped spline invents peaks between two points that a
///   reader would take for data. Clamping is what buys the smooth read without
///   drawing a number nobody measured.
/// * **A mean hairline** ([showAverage]), so "above or below its own normal" is
///   answerable without the reader holding the middle of the range in their
///   head. It is the one reference line a 28px band has room for.
/// * **The last point, ringed** — a filled dot inside a halo the colour of the
///   card, so where the series *ends* stays findable against the fill.
class DashboardSparkline extends StatelessWidget {
  /// Chronological, oldest first. Fewer than two points draws nothing.
  final List<double> values;

  final Color color;
  final double height;

  /// Draws the series' own mean as a hairline. Off for a series of two or
  /// three points, where the mean is not yet a normal to compare against.
  final bool showAverage;

  const DashboardSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 28,
    this.showAverage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          // The halo behind the end dot punches the line out of its own fill,
          // so it has to be the surface the tile is painted on.
          surface: Theme.of(context).colorScheme.surface,
          showAverage: showAverage && values.length >= 4,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.surface,
    required this.showAverage,
  });

  final List<double> values;
  final Color color;
  final Color surface;
  final bool showAverage;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    var min = values.first;
    var max = values.first;
    var sum = 0.0;
    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
      sum += value;
    }

    final range = max - min;
    final stepX = size.width / (values.length - 1);

    // Room for the end dot and its ring at both extremes of the band, so a
    // peak or a trough is never half-clipped by the card's edge.
    const inset = 3.0;
    final usable = size.height - inset * 2;

    double yFor(double value) {
      final normalised = range == 0 ? 0.5 : (value - min) / range;
      return inset + usable - (normalised * usable);
    }

    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(stepX * i, yFor(values[i])),
    ];

    final path = _smoothPath(points);

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );

    if (showAverage && range > 0) {
      _drawDashedLine(
        canvas,
        y: yFor(sum / values.length),
        width: size.width,
        paint: Paint()
          ..color = color.withValues(alpha: 0.32)
          ..strokeWidth = 1,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 3.4, Paint()..color = surface);
    canvas.drawCircle(last, 2.5, Paint()..color = color);
  }

  /// Catmull-Rom through every point, with each cubic's control points pinned
  /// inside its own segment's vertical range. Without the clamp the spline
  /// overshoots a spike and draws a value above the maximum that was measured.
  static Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final lo = p1.dy < p2.dy ? p1.dy : p2.dy;
      final hi = p1.dy < p2.dy ? p2.dy : p1.dy;

      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        (p1.dy + (p2.dy - p0.dy) / 6).clamp(lo, hi),
        p2.dx - (p3.dx - p1.dx) / 6,
        (p2.dy - (p3.dy - p1.dy) / 6).clamp(lo, hi),
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  static void _drawDashedLine(
    Canvas canvas, {
    required double y,
    required double width,
    required Paint paint,
  }) {
    const dash = 3.0;
    const gap = 3.0;
    for (var x = 0.0; x < width; x += dash + gap) {
      final end = (x + dash) > width ? width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color ||
      old.surface != surface ||
      old.showAverage != showAverage ||
      !_sameValues(old.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
