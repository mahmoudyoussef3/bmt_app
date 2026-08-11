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
class DashboardSparkline extends StatelessWidget {
  /// Chronological, oldest first. Fewer than two points draws nothing.
  final List<double> values;

  final Color color;
  final double height;

  const DashboardSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    var min = values.first;
    var max = values.first;
    for (final value in values) {
      if (value < min) min = value;
      if (value > max) max = value;
    }

    final range = max - min;
    final stepX = size.width / (values.length - 1);
    
    const inset = 1.5;
    final usable = size.height - inset * 2;

    Offset pointAt(int index) {
      final normalised = range == 0 ? 0.5 : (values[index] - min) / range;
      return Offset(
        stepX * index,
        inset + usable - (normalised * usable),
      );
    }

    final path = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      path.lineTo(point.dx, point.dy);
    }

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
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      pointAt(values.length - 1),
      2.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || !_sameValues(old.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
