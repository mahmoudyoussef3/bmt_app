import 'package:flutter/material.dart';

/// The captain app's colours.
///
/// Everything that isn't a caution or a failure comes from **one blue family**
/// anchored on [primary]. Positive states are a tint of the brand rather than
/// the usual green: two accent hues fighting on one screen is what made the app
/// look assembled instead of designed. Amber and red survive because a warning
/// that shares the brand hue stops reading as a warning.
class CaptainColors {
  // Brand palette — [primary] is the anchor; the others are its shades, so an
  // accent can never introduce a competing hue.
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color onPrimary = Colors.white;

  /// The deep end of the brand gradient (Indigo 700). Pairs with [primary] to
  /// give the splash mark, auth lockup and profile header a shared identity.
  static const Color primaryDeep = Color(0xFF4338CA);

  /// The pale end of the palette (Blue 400) — for the earliest step of a
  /// progression, before it reaches full [primary].
  static const Color primaryLight = Color(0xFF60A5FA);

  /// The bright end of the palette (Sky 500). Reads as "done / good" while
  /// staying inside the blue family — this is what replaced the old green.
  static const Color primaryBright = Color(0xFF0EA5E9);

  // Semantic
  static const Color online = primaryBright;
  static const Color offline = Color(0xFF64748B); // Slate 500
  static const Color tripActive = primary;
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color success = primaryBright;

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
