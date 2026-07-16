import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

/// A slow, breathing radial glow rendered behind the splash brand.
///
/// Driven by an external repeating controller so the intro sequence and the
/// ambient loop advance independently of each other.
class CaptainSplashBackdrop extends StatelessWidget {
  const CaptainSplashBackdrop({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 0.85 + (t * 0.35),
              colors: [
                CaptainColors.primary.withAlpha(30 + (t * 18).round()),
                CaptainColors.backgroundFor(context).withAlpha(0),
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
