import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// A slow, breathing radial glow rendered behind the splash brand.
///
/// Driven by an external repeating controller so the intro sequence and the
/// ambient loop can advance independently.
class SplashGlowBackdrop extends StatelessWidget {
  const SplashGlowBackdrop({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final radius = 0.85 + (t * 0.35);
        final topAlpha = 30 + (t * 18).round();
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: radius,
              colors: [
                ClientColors.primary.withAlpha(topAlpha),
                ClientColors.backgroundFor(context).withAlpha(0),
              ],
              stops: const [0.0, 0.72],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
