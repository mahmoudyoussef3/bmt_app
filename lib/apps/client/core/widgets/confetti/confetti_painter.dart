import 'package:flutter/material.dart';

import 'confetti_controller.dart';
import 'confetti_particle.dart';

/// Paints the flecks currently in flight on [controller].
///
/// Repaints are driven by the controller itself (`super.repaint`), so the
/// simulation never rebuilds a widget.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.controller) : super(repaint: controller);

  final ConfettiController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final particle in controller.particles) {
      paint.color = particle.color;
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size / ConfettiParticle.aspectRatio,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
