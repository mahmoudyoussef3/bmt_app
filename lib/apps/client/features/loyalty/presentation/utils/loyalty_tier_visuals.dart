import 'package:flutter/material.dart';

import '../../domain/entities/loyalty_tier.dart';

/// Resolves a tier's operator-configured branding into paintable values.
///
/// Living in presentation is what lets the domain carry ARGB ints and an icon
/// key without knowing what either means to Flutter.
extension LoyaltyTierVisuals on LoyaltyTier {
  /// Gradient stops. The model guarantees at least two, so this is always
  /// safe to hand to a [LinearGradient].
  List<Color> get gradient =>
      gradientColors.map(Color.new).toList(growable: false);

  IconData get icon => switch (iconKey) {
    'shield' => Icons.shield_rounded,
    'stars' => Icons.stars_rounded,
    'diamond' => Icons.diamond_rounded,
    'premium' || _ => Icons.workspace_premium_rounded,
  };
}
