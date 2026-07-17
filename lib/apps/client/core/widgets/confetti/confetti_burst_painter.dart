import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/client_colors.dart';

/// A one-shot radial confetti burst driven by an [Animation].
///
/// Distinct from [ConfettiPainter], which simulates falling flecks over time:
/// this is a deterministic outward puff that tracks `progress` 0→1 and fades
/// out. Used for inline success moments where a full physics celebration would
/// be too much.
class ConfettiBurstPainter extends CustomPainter {
  ConfettiBurstPainter({
    required this.progress,
    this.seed = 42,
    this.particleCount = 28,
    this.radiusFactor = 0.7,
    List<Color>? palette,
  }) : palette = palette ?? defaultPalette,
       super(repaint: progress);

  final Animation<double> progress;

  /// Fixed seed keeps the burst's layout stable across repaints — without it
  /// every frame would scatter the flecks somewhere new.
  final int seed;
  final int particleCount;

  /// Burst reach, as a fraction of the paint area's width.
  final double radiusFactor;
  final List<Color> palette;

  static const List<Color> defaultPalette = <Color>[
    ClientColors.primary,
    ClientColors.journeyCyan,
    ClientColors.journeyAmber,
    ClientColors.journeyRed,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value;
    if (value == 0) return;

    final random = math.Random(seed);
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * radiusFactor;
    final fade = (1.0 - value).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = value * maxRadius * (0.4 + random.nextDouble() * 0.6);
      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      final radius = fade * (4 + random.nextDouble() * 6);
      paint.color = palette[random.nextInt(palette.length)].withAlpha(
        (fade * 255).toInt(),
      );
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed ||
      oldDelegate.particleCount != particleCount ||
      oldDelegate.radiusFactor != radiusFactor ||
      !listEquals(oldDelegate.palette, palette);
}
