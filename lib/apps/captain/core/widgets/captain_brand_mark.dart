import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';

class CaptainBrandMark extends StatelessWidget {
  const CaptainBrandMark({super.key, this.icon, this.size = 84});

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
