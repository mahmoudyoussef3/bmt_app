import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class TrackingMapCard extends StatelessWidget {
  final double height;
  final Animation<double> progress;

  const TrackingMapCard({super.key, this.height = 260, required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          return CustomPaint(
            painter: _RoutePainter(progress.value, scheme),
            child: child,
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.5, -0.8),
                        radius: 1.2,
                        colors: [
                          scheme.primary.withAlpha(18),
                          scheme.surface.withAlpha(8),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomSingleVehicle(
                    progress: progress,
                    width: w,
                    height: h,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CustomSingleVehicle extends StatelessWidget {
  final Animation<double> progress;
  final double width;
  final double height;

  const CustomSingleVehicle({
    super.key,
    required this.progress,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final points = _fractionalPoints;
    final t = progress.value.clamp(0.0, 1.0);
    final total = (points.length - 1).toDouble();
    final step = (t * total).clamp(0.0, total);
    final idx = step.floor().toInt();
    final u = step - idx;
    final a = _toOffset(points[idx], width, height);
    final b = _toOffset(
      points[(idx + 1).clamp(0, points.length - 1)],
      width,
      height,
    );
    final pos = Offset(lerpDouble(a.dx, b.dx, u)!, lerpDouble(a.dy, b.dy, u)!);

    return Stack(
      children: [
        Positioned(
          left: pos.dx - 12,
          top: pos.dy - 12,
          child: _VehicleMarker(),
        ),
      ],
    );
  }

  Offset _toOffset(Offset f, double w, double h) => Offset(f.dx * w, f.dy * h);

  static const _fractionalPoints = [
    Offset(0.12, 0.78),
    Offset(0.2, 0.6),
    Offset(0.36, 0.52),
    Offset(0.55, 0.46),
    Offset(0.7, 0.34),
    Offset(0.86, 0.22),
  ];
}

class _VehicleMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withAlpha(200)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double t;
  final ColorScheme scheme;
  _RoutePainter(this.t, this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.surfaceContainerHighest.withAlpha(240),
          scheme.surface.withAlpha(240),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = scheme.outline.withAlpha(20)
      ..strokeWidth = 1;
    for (var x = 0.18; x < 1; x += 0.2) {
      final dx = size.width * x;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0.22; y < 1; y += 0.2) {
      final dy = size.height * y;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final points = CustomSingleVehicle._fractionalPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final base = Paint()
      ..color = scheme.onSurface.withAlpha(34)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, base);

    final progressPath = Path();
    final progressLength = t.clamp(0.0, 1.0);
    if (progressLength > 0) {
      final segCount = points.length - 1;
      final total = segCount.toDouble();
      final upto = progressLength * total;
      final fullSegs = upto.floor();
      final rem = upto - fullSegs;
      progressPath.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i <= fullSegs && i < points.length; i++) {
        progressPath.lineTo(points[i].dx, points[i].dy);
      }
      if (fullSegs < segCount) {
        final a = points[fullSegs];
        final b = points[fullSegs + 1];
        final mid = Offset(
          lerpDouble(a.dx, b.dx, rem)!,
          lerpDouble(a.dy, b.dy, rem)!,
        );
        progressPath.lineTo(mid.dx, mid.dy);
      }
      final prog = Paint()
        ..color = scheme.primary.withAlpha(230)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(progressPath, prog);
    }

    final stopPaint = Paint();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final isDone = i <= ((t * (points.length - 1)).floor());
      stopPaint.color = isDone
          ? scheme.primary
          : scheme.onSurface.withAlpha(120);
      canvas.drawCircle(p, 5, stopPaint);
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = isDone ? scheme.primary.withAlpha(18) : Colors.transparent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.t != t || old.scheme != scheme;
}
