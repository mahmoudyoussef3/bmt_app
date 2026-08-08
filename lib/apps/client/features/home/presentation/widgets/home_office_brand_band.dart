import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The letterhead strip across the top of an operator tile.
///
/// It exists to give the card an anchor: without it the tile was a name
/// floating in white space, which read as an avatar rather than as a company.
/// The bus glyph is cropped by the band's own edge so the mark feels stamped
/// into the card instead of dropped on top of it.
class HomeOfficeBrandBand extends StatelessWidget {
  const HomeOfficeBrandBand({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(isDark ? 10 : 25),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(isDark ? 5 : 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
