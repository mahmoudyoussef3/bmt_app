import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';

/// The rounded, elevated brand tile — the captain app's identity anchor.
///
/// Shared by the splash, the auth lockup and the onboarding views so the same
/// mark greets the captain from cold start through to sign-in, rather than
/// each screen rolling its own gradient tile.
class CaptainBrandMark extends StatelessWidget {
  const CaptainBrandMark({super.key, this.icon, this.size = 84});

  /// Glyph drawn inside the tile. When null the EasyWay logo mark is used —
  /// the same glyph the launcher icon and the native launch frame carry.
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
        // Tracks the tile so the squircle reads the same at every size.
        borderRadius: BorderRadius.circular(size * 0.31),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(80),
            blurRadius: size * 0.38,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: scheme.onPrimary)
          : Padding(
              padding: EdgeInsets.all(size * 0.19),
              child: Image.asset(
                'assets/branding/brand_glyph.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.directions_bus_rounded,
                  size: size * 0.5,
                  color: scheme.onPrimary,
                ),
              ),
            ),
    );
  }
}
