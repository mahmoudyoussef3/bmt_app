import 'package:flutter/material.dart';

/// Centralized, semantic color palette used across the app.
/// Client app light: `#FAFAF5` background, `#2563EB` primary.
/// Client app dark: `#1F1F1F` background, `#00D9FF` primary.
class AppColors {
  AppColors._();

  // Light theme
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryForeground = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFFFB923C);
  static const Color accentForeground = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFAFAF5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color popover = Color(0xFFFFFFFF);

  static const Color foreground = Color(0xFF1F2937);
  static const Color cardForeground = Color(0xFF1F2937);
  static const Color popoverForeground = Color(0xFF1F2937);

  static const Color muted = Color(0xFFF0F0EB);
  static const Color mutedForeground = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color input = Color(0xFFFFFFFF);

  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  static const Color ring = Color(0xFF2563EB);

  // Dark theme
  static const Color primaryDark = Color(0xFF00D9FF);
  static const Color primaryForegroundDark = Color(0xFF1F1F1F);

  static const Color secondaryDark = Color(0xFF06B6D4);
  static const Color secondaryForegroundDark = Color(0xFFF2F2F2);

  static const Color accentDark = Color(0xFFFB923C);
  static const Color accentForegroundDark = Color(0xFF1F1F1F);

  static const Color backgroundDark = Color(0xFF1F1F1F);
  static const Color cardDark = Color(0xFF2D2D3D);
  static const Color popoverDark = Color(0xFF2D2D3D);

  static const Color foregroundDark = Color(0xFFF2F2F2);
  static const Color mutedDark = Color(0xFF4A4A5A);
  static const Color mutedForegroundDark = Color(0xFFA6A6A6);
  static const Color borderDark = Color(0xFF454555);
  static const Color inputDark = Color(0xFF383848);

  static const Color destructiveDark = Color(0xFFDC2626);
  static const Color ringDark = Color(0xFF00D9FF);
}

/// Semantic status color pairs — all WCAG AA 4.5:1 compliant on their own container.
/// Use [container] as chip background, [onContainer] as chip text/icon color.
class AppStatusColors {
  AppStatusColors._();

  // Success (green)
  static const Color successContainer   = Color(0xFFDCFCE7); // green-100
  static const Color onSuccessContainer = Color(0xFF166534); // green-800

  // Warning (amber)
  static const Color warningContainer   = Color(0xFFFEF9C3); // yellow-100
  static const Color onWarningContainer = Color(0xFF854D0E); // yellow-800

  // Error / danger (red)
  static const Color errorContainer   = Color(0xFFFEE2E2); // red-100
  static const Color onErrorContainer = Color(0xFF991B1B); // red-800

  // Info (blue)
  static const Color infoContainer   = Color(0xFFDBEAFE); // blue-100
  static const Color onInfoContainer = Color(0xFF1E40AF); // blue-800

  // Neutral (gray)
  static const Color neutralContainer   = Color(0xFFF3F4F6); // gray-100
  static const Color onNeutralContainer = Color(0xFF374151); // gray-700

  // Special / accent (purple — used for "contacted" state)
  static const Color specialContainer   = Color(0xFFF3E8FF); // purple-100
  static const Color onSpecialContainer = Color(0xFF6B21A8); // purple-800
}

ColorScheme lightColorSchemeFromPalette() {
  return const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.primaryForeground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.secondaryForeground,
    tertiary: AppColors.accent,
    onTertiary: AppColors.accentForeground,
    error: AppColors.destructive,
    onError: AppColors.destructiveForeground,
    surface: AppColors.card,
    onSurface: AppColors.foreground,
    surfaceContainerHighest: AppColors.muted,
    surfaceContainerLow: AppColors.background,
    surfaceContainerLowest: AppColors.background,
    outline: AppColors.border,
  );
}

ColorScheme darkColorSchemeFromPalette() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.primaryForegroundDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.secondaryForegroundDark,
    tertiary: AppColors.accentDark,
    onTertiary: AppColors.accentForegroundDark,
    error: AppColors.destructiveDark,
    onError: AppColors.foregroundDark,
    surface: AppColors.cardDark,
    onSurface: AppColors.foregroundDark,
    surfaceContainerHighest: AppColors.backgroundDark,
    surfaceContainerLow: AppColors.cardDark,
    surfaceContainerLowest: AppColors.cardDark,
    outline: AppColors.borderDark,
  );
}
