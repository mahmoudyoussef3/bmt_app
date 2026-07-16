import 'package:flutter/material.dart';

import 'captain_colors.dart';

/// The single source of spacing, radius and shadow values for the captain app.
///
/// The scale is deliberately numeric (`s16`, `br24`) rather than semantic
/// (`lg`, `rXl`): captain screens are dense operational layouts where the
/// literal value is the useful information at the call site.
class CaptainDesignTokens {
  CaptainDesignTokens._();

  // Spacing
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Radius
  static const Radius r8 = Radius.circular(8);
  static const Radius r12 = Radius.circular(12);
  static const Radius r16 = Radius.circular(16);
  static const Radius r24 = Radius.circular(24);
  static const Radius r32 = Radius.circular(32);

  /// Fully rounded ends — chips, pills and progress tracks.
  static const Radius rPill = Radius.circular(999);

  static const BorderRadius br8 = BorderRadius.all(r8);
  static const BorderRadius br12 = BorderRadius.all(r12);
  static const BorderRadius br16 = BorderRadius.all(r16);
  static const BorderRadius br24 = BorderRadius.all(r24);
  static const BorderRadius br32 = BorderRadius.all(r32);
  static const BorderRadius brPill = BorderRadius.all(rPill);

  // Shadows
  static List<BoxShadow> softShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : CaptainColors.primary.withValues(alpha: 0.05),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ];
  }

  static List<BoxShadow> floatingShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.4)
            : CaptainColors.primary.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
    ];
  }
}
