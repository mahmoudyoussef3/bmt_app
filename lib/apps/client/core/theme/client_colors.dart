import 'package:flutter/material.dart';

/// Client-app semantic color tokens.
///
/// These are fixed palette values intentionally decoupled from the Material 3
/// [ColorScheme] seed so that journey-state colors (cyan = confirmed,
/// amber = attention, red = cancelled) stay consistent across both light and
/// dark themes without being overridden by tonal palettes.
///
/// The palette carries no green: the "confirmed / on-time / active" role is a
/// cyan that sits in the same blue family as [primary], so success reads as
/// part of the brand rather than as a foreign accent.
///
/// Use [ClientColors.of] to access theme-aware surface/text values.
/// Use the static journey constants directly for status colors.
abstract final class ClientColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryMuted = Color(0xFF93C5FD);
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFF6366F1); // Indigo

  static const Color darkPrimary = Color(
    0xFF3B82F6,
  ); // Lighter Blue for Dark Mode
  static const Color darkPrimaryStrong = Color(0xFF60A5FA);
  static const Color darkPrimaryLight = Color(0xFF1E3A8A);
  static const Color darkSecondary = Color(0xFF38BDF8);
  static const Color darkAccent = Color(0xFF818CF8);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Deep three-stop sweep used by the home hero canvas. Kept darker than
  // [primaryGradient] so white text and the search pill hold AAA contrast.
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Journey status ─────────────────────────────────────────────────────────
  // Cyan — confirmed booking, on-time, boarded, active trip. Deliberately in
  // the blue family so it harmonizes with [primary]; it stays readable against
  // it because it is far lighter and far less violet.
  static const Color journeyCyan = Color(0xFF0891B2);
  static const Color journeyCyanLight = Color(0xFFCFFAFE);
  static const Color onJourneyCyan = Color(0xFF164E63);

  /// Stronger cyan for gradient tails and filled success surfaces.
  static const Color journeyCyanStrong = Color(0xFF06B6D4);

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

  // ── Seat map ───────────────────────────────────────────────────────────────
  // Selectable seats stay in the brand blue family so a picked seat (solid
  // [primary]) reads as the same object in a stronger state, and grey is left
  // to mean "not selectable".
  static const Color seatAvailable = Color(0xFFEFF6FF);
  static const Color seatAvailableBorder = Color(0xFFBFDBFE);
  static const Color onSeatAvailable = Color(0xFF1D4ED8);

  static const Color _darkSeatAvailable = Color(0xFF17233F);
  static const Color _darkSeatAvailableBorder = Color(0xFF1E3A8A);
  static const Color _darkOnSeatAvailable = Color(0xFF93C5FD);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF8793A4);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF9FAFB); // Gray 50
  static const Color surfaceMuted = Color(0xFFF3F4F6); // Gray 100
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderStrong = Color(0xFFD1D5DB); // Gray 300

  // ── Dark-mode overrides (used when [Brightness.dark]) ─────────────────────
  static const Color _darkBackground = Color(0xFF0B1220);
  static const Color _darkSurface = Color(0xFF111827); // Gray 900
  static const Color _darkSurfaceSubtle = Color(0xFF1F2937); // Gray 800
  static const Color _darkSurfaceMuted = Color(0xFF374151); // Gray 700
  static const Color _darkSurfaceRaised = Color(0xFF1F2937);
  static const Color _darkBorder = Color(0xFF374151);
  static const Color _darkBorderStrong = Color(0xFF4B5563);
  static const Color _darkTextPrimary = Color(0xFFF9FAFB);
  static const Color _darkTextSecondary = Color(0xFF9CA3AF);
  static const Color _darkTextTertiary = Color(0xFF6B7280);

  // ── Theme-aware accessors ──────────────────────────────────────────────────

  /// Returns the theme-appropriate surface color.
  static Color surfaceFor(BuildContext context) =>
      _isDark(context) ? _darkSurface : surface;

  static Color backgroundFor(BuildContext context) =>
      _isDark(context) ? _darkBackground : surfaceSubtle;

  static Color surfaceSubtleFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceSubtle : surfaceSubtle;

  static Color surfaceMutedFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceMuted : surfaceMuted;

  static Color surfaceRaisedFor(BuildContext context) =>
      _isDark(context) ? _darkSurfaceRaised : surfaceRaised;

  static Color borderFor(BuildContext context) =>
      _isDark(context) ? _darkBorder : border;

  static Color borderStrongFor(BuildContext context) =>
      _isDark(context) ? _darkBorderStrong : borderStrong;

  static Gradient primaryGradientFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryGradient : primaryGradient;

  static Gradient heroGradientFor(BuildContext context) =>
      _isDark(context) ? darkHeroGradient : heroGradient;

  /// First stop of the hero gradient — used for the pinned status-bar strip
  /// and the overscroll fill so the hero reads as one continuous surface.
  static Color heroTopFor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A);

  static Color textPrimaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextPrimary : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextSecondary : textSecondary;

  static Color textTertiaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextTertiary : textTertiary;

  static Color primaryFor(BuildContext context) =>
      _isDark(context) ? darkPrimary : primary;

  static Color primaryContainerFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryLight : primaryLight;

  static Color seatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailable : seatAvailable;

  static Color seatAvailableBorderFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailableBorder : seatAvailableBorder;

  static Color onSeatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkOnSeatAvailable : onSeatAvailable;

  static Color shadowFor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF020617) : const Color(0xFF1E293B);

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
        bg: journeyCyanLight,
        fg: onJourneyCyan,
        label: journeyCyan,
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

  static ({Color bg, Color fg, Color label}) journeyBadgeFor(
    BuildContext context,
    ClientJourneyStatus status,
  ) {
    if (!_isDark(context)) return journeyBadge(status);
    return switch (status) {
      ClientJourneyStatus.active => (
        bg: const Color(0xFF0C3946),
        fg: const Color(0xFFA5F3FC),
        label: const Color(0xFF22D3EE),
      ),
      ClientJourneyStatus.upcoming => (
        bg: darkPrimaryLight,
        fg: const Color(0xFFD8E8FF),
        label: darkPrimary,
      ),
      ClientJourneyStatus.departing => (
        bg: const Color(0xFF3A2A0A),
        fg: const Color(0xFFFFE7A3),
        label: darkAccent,
      ),
      ClientJourneyStatus.completed => (
        bg: const Color(0xFF1F2937),
        fg: const Color(0xFFD1D5DB),
        label: const Color(0xFF94A3B8),
      ),
      ClientJourneyStatus.cancelled => (
        bg: const Color(0xFF3A1518),
        fg: const Color(0xFFFFC6CC),
        label: const Color(0xFFFB7185),
      ),
    };
  }
}

/// The five lifecycle states a trip or booking can be in from the passenger's
/// perspective. Maps to the color pairs returned by [ClientColors.journeyBadge].
enum ClientJourneyStatus { active, upcoming, departing, completed, cancelled }
