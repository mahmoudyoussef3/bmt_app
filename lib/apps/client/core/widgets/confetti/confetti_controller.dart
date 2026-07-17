import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'confetti_particle.dart';

/// Drives a confetti celebration for [ConfettiOverlay].
///
/// Doubles as the overlay painter's `repaint` [Listenable], so advancing the
/// simulation repaints the overlay *without* rebuilding any widget. Screens
/// hold one of these and call [fire]; they never rebuild per frame.
class ConfettiController extends ChangeNotifier {
  ConfettiController({this.particleCount = 90, List<Color>? palette})
    : palette = palette ?? Colors.primaries;

  /// Flecks spawned per burst.
  final int particleCount;

  /// Colors flecks are drawn from. Confetti reads as celebratory precisely
  /// because it is polychrome, so this deliberately defaults to the full
  /// Material palette rather than the brand's few [ClientColors] accents.
  final List<Color> palette;

  final List<ConfettiParticle> _particles = <ConfettiParticle>[];
  final math.Random _random = math.Random();
  bool _burstRequested = false;

  /// Flecks in flight. Read by the painter on each repaint.
  List<ConfettiParticle> get particles => _particles;

  bool get isActive => _particles.isNotEmpty || _burstRequested;

  /// Requests a burst. Safe to call from any callback: the flecks are spawned
  /// on the next frame by [ConfettiOverlay], once its real bounds are known.
  void fire() {
    _burstRequested = true;
    notifyListeners();
  }

  /// Spawns a requested burst inside [bounds]. Called by [ConfettiOverlay].
  void spawnPendingBurst(Size bounds) {
    if (!_burstRequested) return;
    _burstRequested = false;
    _particles.clear();
    final originX = bounds.width / 2;
    final originY = bounds.height / 3;
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 4 + _random.nextDouble() * 11;
      _particles.add(
        ConfettiParticle(
          x: originX,
          y: originY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 6,
          size: 6 + _random.nextDouble() * 8,
          color: palette[_random.nextInt(palette.length)],
          rotation: _random.nextDouble() * math.pi,
          rotationSpeed: -0.1 + _random.nextDouble() * 0.2,
        ),
      );
    }
  }

  /// Advances the simulation one step, retiring flecks that fell past
  /// [bounds]. Returns whether any fleck is still in flight.
  bool advance(Size bounds) {
    for (final particle in _particles) {
      particle.update();
    }
    _particles.removeWhere((particle) => particle.y > bounds.height);
    notifyListeners();
    return _particles.isNotEmpty;
  }

  @override
  void dispose() {
    _particles.clear();
    super.dispose();
  }
}
