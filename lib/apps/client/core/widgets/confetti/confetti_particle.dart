import 'package:flutter/material.dart';

/// A single confetti fleck advanced by [ConfettiController]'s simulation.
///
/// Mutable by design: the simulation advances thousands of particle steps per
/// celebration, and reallocating an immutable particle per frame would churn
/// the heap for no benefit.
class ConfettiParticle {
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  /// Gravity applied to [vy] each step.
  static const double gravity = 0.22;

  /// Horizontal drag multiplier applied to [vx] each step.
  static const double drag = 0.98;

  /// Rendered width-to-height ratio of a fleck.
  static const double aspectRatio = 1.5;

  void update() {
    x += vx;
    y += vy;
    vy += gravity;
    vx *= drag;
    rotation += rotationSpeed;
  }
}
