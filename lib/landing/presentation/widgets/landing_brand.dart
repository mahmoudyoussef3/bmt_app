import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';

/// The EWT mark, as the apps actually ship it.
///
/// `assets/images/app_icon.png` is the launcher icon on all three apps, so
/// the site's header wears the same tile a reader will later tap on their
/// phone. The rounded clip is the only thing drawn here — the blue ground and
/// the glyph are the icon's own, not a re-drawing of them, which is what keeps
/// the site from drifting away from the product when the icon changes.
///
/// [onDark] only swaps the wordmark's ink; the tile is identical on both the
/// paper header and the navy footer, because a mark that changes colour with
/// its background stops being recognisable as one mark.
class LandingBrandMark extends StatelessWidget {
  const LandingBrandMark({
    super.key,
    this.tileSize = 42,
    this.showWordmark = true,
    this.onDark = false,
  });

  final double tileSize;
  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LandingBrandTile(size: tileSize),
        if (showWordmark) ...[
          SizedBox(width: tileSize * 0.26),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EWT',
                  style:
                      LandingType.metric(
                        tileSize * 0.45,
                        color: onDark ? Colors.white : LandingPalette.ink,
                      ).copyWith(
                        letterSpacing: -0.4,
                        // The wordmark is a Latin run; in an RTL page it needs
                        // its own direction or the two lines drift apart.
                        height: 1.15,
                      ),
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  'Easy Way Transportation',
                  style: LandingType.label(
                    tileSize * 0.25,
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : LandingPalette.muted,
                    weight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The icon tile on its own — used where the wordmark is already spelled out
/// by the copy beside it.
class LandingBrandTile extends StatelessWidget {
  const LandingBrandTile({super.key, this.size = 42, this.glow = true});

  final double size;

  /// The brand-coloured bloom under the tile. Dropped where the tile sits on
  /// an already-busy ground, such as over a product shot.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: LandingPalette.brand.withValues(alpha: 0.42),
                  offset: Offset(0, size * 0.18),
                  blurRadius: size * 0.42,
                  spreadRadius: -size * 0.18,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          // The header must still read if the asset is missing from a build.
          errorBuilder: (_, _, _) => DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [LandingPalette.brand, LandingPalette.navy],
              ),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
