import 'package:flutter/material.dart';

class CaptainColors {
  // Brand
  static const Color primary = Color(0xFF2563EB); // Vibrant Blue
  static const Color onPrimary = Colors.white;

  /// The deep end of the brand gradient (Indigo 700). Pairs with [primary] to
  /// give the splash mark, auth lockup and profile header a shared identity.
  static const Color primaryDeep = Color(0xFF4338CA);

  // Semantic
  static const Color online = Color(0xFF10B981); // Emerald 500
  static const Color offline = Color(0xFF64748B); // Slate 500
  static const Color tripActive = Color(0xFF2563EB); // Blue 600
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF22C55E); // Green 500

  /// Star/rating gold. Distinct from [warning] on purpose: a rating is not a
  /// caution state, and the two must stay independently tunable.
  static const Color rating = Color(0xFFFBBF24); // Amber 400

  // Backgrounds & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Borders & Dividers
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // Helper Methods
  static Color backgroundFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  static Color textPrimaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static Color textSecondaryFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }

  static Color dividerFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : dividerLight;
  }

  /// The brand gradient used by the splash mark, auth lockup and profile
  /// header, so the captain sees one identity across all three.
  static LinearGradient primaryGradient(BuildContext context) {
    return LinearGradient(
      colors: [Theme.of(context).colorScheme.primary, primaryDeep],
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
    );
  }
}
