import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaptainTypography {
  static TextTheme textTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildTheme(isDark);
  }

  static TextTheme textThemeFromBrightness(Brightness brightness) {
    return _buildTheme(brightness == Brightness.dark);
  }

  static TextTheme _buildTheme(bool isDark) {
    final color = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final base = GoogleFonts.cairoTextTheme().apply(
      bodyColor: color,
      displayColor: color,
    );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: color,
        height: 1.1,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: color,
        height: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.4,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: mutedColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: mutedColor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: mutedColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // Helpers for quick access
  static TextStyle displayLarge(BuildContext context) =>
      textTheme(context).displayLarge!;
  static TextStyle displayMedium(BuildContext context) =>
      textTheme(context).displayMedium!;
  static TextStyle displaySmall(BuildContext context) =>
      textTheme(context).displaySmall!;
  static TextStyle headlineLarge(BuildContext context) =>
      textTheme(context).headlineLarge!;
  static TextStyle headlineMedium(BuildContext context) =>
      textTheme(context).headlineMedium!;
  static TextStyle headlineSmall(BuildContext context) =>
      textTheme(context).headlineSmall!;
  static TextStyle titleLarge(BuildContext context) =>
      textTheme(context).titleLarge!;
  static TextStyle titleMedium(BuildContext context) =>
      textTheme(context).titleMedium!;
  static TextStyle titleSmall(BuildContext context) =>
      textTheme(context).titleSmall!;
  static TextStyle bodyLarge(BuildContext context) =>
      textTheme(context).bodyLarge!;
  static TextStyle bodyMedium(BuildContext context) =>
      textTheme(context).bodyMedium!;
  static TextStyle bodySmall(BuildContext context) =>
      textTheme(context).bodySmall!;
  static TextStyle labelLarge(BuildContext context) =>
      textTheme(context).labelLarge!;
  static TextStyle labelMedium(BuildContext context) =>
      textTheme(context).labelMedium!;
  static TextStyle labelSmall(BuildContext context) =>
      textTheme(context).labelSmall!;
}
