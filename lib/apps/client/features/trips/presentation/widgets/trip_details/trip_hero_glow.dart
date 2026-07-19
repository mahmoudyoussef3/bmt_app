import 'package:flutter/material.dart';

/// A soft off-canvas light source — calmer than the oversized bus glyph the
/// hero used to stamp across its corner.
class TripHeroGlow extends StatelessWidget {
  const TripHeroGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withAlpha(46), Colors.white.withAlpha(0)],
        ),
      ),
    );
  }
}
