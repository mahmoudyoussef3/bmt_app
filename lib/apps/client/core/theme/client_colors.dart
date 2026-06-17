import 'package:flutter/material.dart';

/// Client-app semantic color tokens.
///
/// These are fixed palette values intentionally decoupled from the Material 3
/// [ColorScheme] seed so that journey-state colors (green = confirmed,
/// amber = attention, red = cancelled) stay consistent across both light and
/// dark themes without being overridden by tonal palettes.
///
/// Use [ClientColors.of] to access theme-aware surface/text values.
/// Use the static journey constants directly for status colors.
abstract final class ClientColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B6EF3);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color primaryMuted = Color(0xFF6B9FF8);

  // ── Journey status ─────────────────────────────────────────────────────────
  // Green — confirmed booking, on-time, boarded, active trip
  static const Color journeyGreen = Color(0xFF16A34A);
  static const Color journeyGreenLight = Color(0xFFDCFCE7);
  static const Color onJourneyGreen = Color(0xFF14532D);

  // Amber — departing soon, seat scarcity, attention needed
  static const Color journeyAmber = Color(0xFFD97706);
  static const Color journeyAmberLight = Color(0xFFFEF3C7);
  static const Color onJourneyAmber = Color(0xFF78350F);

  // Red — cancelled, trip full, expired, error
  static const Color journeyRed = Color(0xFFDC2626);
  static const Color journeyRedLight = Color(0xFFFEE2E2);
  static const Color onJourneyRed = Color(0xFF7F1D1D);

  // Slate — completed, inactive history, dimmed states
  static const Color journeySlate = Color(0xFF64748B);
  static const Color journeySlateLight = Color(0xFFF1F5F9);
  static const Color onJourneySlate = Color(0xFF1E293B);

  // Purple — packages, subscriptions, premium
  static const Color journeyPurple = Color(0xFF7C3AED);
  static const Color journeyPurpleLight = Color(0xFFF5F3FF);
  static const Color onJourneyPurple = Color(0xFF3B0764);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // ── Dark-mode overrides (used when [Brightness.dark]) ─────────────────────
  static const Color _darkSurface = Color(0xFF0F172A);
  static const Color _darkSurfaceSubtle = Color(0xFF1E293B);
  static const Color _darkSurfaceMuted = Color(0xFF334155);
  static const Color _darkBorder = Color(0xFF334155);
  static const Color _darkBorderStrong = Color(0xFF475569);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC);
  static const Color _darkTextSecondary = Color(0xFFCBD5E1);
  static const Color _darkTextTertiary = Color(0xFF64748B);

  // ── Theme-aware accessors ──────────────────────────────────────────────────

  /// Returns the theme-appropriate surface color.
  static Color surfaceFor(BuildContext context) => _isDark(context)
      ? _darkSurface
      : surface;

  static Color surfaceSubtleFor(BuildContext context) => _isDark(context)
      ? _darkSurfaceSubtle
      : surfaceSubtle;

  static Color surfaceMutedFor(BuildContext context) => _isDark(context)
      ? _darkSurfaceMuted
      : surfaceMuted;

  static Color borderFor(BuildContext context) => _isDark(context)
      ? _darkBorder
      : border;

  static Color borderStrongFor(BuildContext context) => _isDark(context)
      ? _darkBorderStrong
      : borderStrong;

  static Color textPrimaryFor(BuildContext context) => _isDark(context)
      ? _darkTextPrimary
      : textPrimary;

  static Color textSecondaryFor(BuildContext context) => _isDark(context)
      ? _darkTextSecondary
      : textSecondary;

  static Color textTertiaryFor(BuildContext context) => _isDark(context)
      ? _darkTextTertiary
      : textTertiary;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Journey helpers ────────────────────────────────────────────────────────

  /// Returns `(background, foreground, label-color)` for a given [status].
  /// Covers the five canonical journey states that appear on trip and booking
  /// cards throughout the client app.
  static ({Color bg, Color fg, Color label}) journeyBadge(
    ClientJourneyStatus status,
  ) {
    return switch (status) {
      ClientJourneyStatus.active => (
          bg: journeyGreenLight,
          fg: onJourneyGreen,
          label: journeyGreen,
        ),
      ClientJourneyStatus.upcoming => (
          bg: primaryLight,
          fg: primary,
          label: primary,
        ),
      ClientJourneyStatus.departing => (
          bg: journeyAmberLight,
          fg: onJourneyAmber,
          label: journeyAmber,
        ),
      ClientJourneyStatus.completed => (
          bg: journeySlateLight,
          fg: onJourneySlate,
          label: journeySlate,
        ),
      ClientJourneyStatus.cancelled => (
          bg: journeyRedLight,
          fg: onJourneyRed,
          label: journeyRed,
        ),
    };
  }
}

/// The five lifecycle states a trip or booking can be in from the passenger's
/// perspective. Maps to the color pairs returned by [ClientColors.journeyBadge].
enum ClientJourneyStatus {
  active,
  upcoming,
  departing,
  completed,
  cancelled,
}
