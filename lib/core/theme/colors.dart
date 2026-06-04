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
