import 'package:flutter/material.dart';

/// Two soft discs cropped by the band they sit in, so a brand surface reads as
/// printed stock rather than a flat fill.
///
/// Shared by the directory masthead and the profile hero: the two screens are
/// one journey, and a rider who taps a listing should land on the same
/// letterhead they tapped from.
///
/// Meant to be dropped into a `Positioned.fill` inside a clipped, gradient
/// container — it paints nothing of its own and never intercepts a tap.
///
/// [scale] shrinks the whole arrangement for short bands. At full size on a
/// 60px rail tile the discs are so much larger than the band that only a flat
/// wash of their interiors shows, which reads as a printing smudge rather than
/// as an arc.
class OfficeBrandDecor extends StatelessWidget {
  const OfficeBrandDecor({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          PositionedDirectional(
            top: -60 * scale,
            end: -40 * scale,
            child: _Disc(size: 200 * scale, alpha: isDark ? 10 : 26),
          ),
          PositionedDirectional(
            top: 40 * scale,
            start: -70 * scale,
            child: _Disc(size: 160 * scale, alpha: isDark ? 6 : 16),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha});

  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(alpha),
      ),
    );
  }
}
