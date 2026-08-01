import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';

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
/// ## Light values live here; dark values live in [AppDarkColors]
///
/// The light half of this file is the client app's own. The dark half is not:
/// every `_dark*` value below now forwards to [AppDarkColors], the one palette
/// the captain app is also drawn in.
///
/// That forwarding is the whole point of the pass. This file used to carry a
/// **Tailwind grey** dark ladder (`#111827` / `#1F2937` / `#374151`) while the
/// captain app and the shared [ColorScheme] were on **slate**
/// (`#0F172A` / `#1E293B` / `#334155`). Greys and slates are close enough to
/// look like a rendering bug rather than a decision when they meet — and they
/// met constantly, because a client screen draws its scaffold from the shared
/// theme (slate) and its cards from here (grey). Both halves now come off one
/// ladder, so a screen cannot drift.
///
/// Use the `*For(context)` accessors for anything that has to survive a theme
/// switch. The bare constants are light-mode values and are safe to use
/// unresolved only where a colour is a **mark** rather than text — a dot, an
/// icon, a 1px rule — which clears the 3:1 non-text floor in both modes. Text
/// and fills must go through an accessor; no single constant can clear the
/// 4.5:1 text floor against both white and slate.
abstract final class ClientColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryMuted = Color(0xFF93C5FD);
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFF6366F1); // Indigo

  /// Brand blue as **ink** on a dark page. [primary] itself is only 3.66:1 on
  /// [AppDarkColors.background] — under the text floor — so anything drawn as
  /// a label, icon or thin rule uses this instead. See [primaryFor].
  static const Color darkPrimary = AppDarkColors.primaryAccent;

  /// Brand blue as a **fill** on a dark page: the tone that carries white
  /// text on it. See [primaryFillFor].
  static const Color darkPrimaryFill = AppDarkColors.primary;

  static const Color darkPrimaryStrong = AppDarkColors.primaryAccent;
  static const Color darkPrimaryLight = AppDarkColors.primaryContainer;
  static const Color darkSecondary = AppDarkColors.successInk;
  static const Color darkAccent = AppDarkColors.special;

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The dark-mode brand sweep. Runs [AppDarkColors.primary] into
  /// [AppDarkColors.primaryDeep] — the same two stops as the captain profile
  /// header, which is where this whole palette comes from.
  static const Gradient darkPrimaryGradient = AppDarkColors.brandGradient;

  // Deep three-stop sweep used by the home hero canvas. Kept darker than
  // [primaryGradient] so white text and the search pill hold AAA contrast.
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The dark hero. Starts on the page colour so the hero grows out of the
  /// scaffold instead of sitting on it as a separate slab, then climbs through
  /// the brand container into full brand blue.
  static const Gradient darkHeroGradient = LinearGradient(
    colors: [
      AppDarkColors.background,
      AppDarkColors.primaryContainer,
      AppDarkColors.primary,
    ],
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

  /// Deeper amber for gradient tails and filled attention surfaces.
  static const Color journeyAmberStrong = Color(0xFFB45309); // Amber 700

  // Red — cancelled, trip full, expired, error
  static const Color journeyRed = Color(0xFFDC2626);
  static const Color journeyRedLight = Color(0xFFFEE2E2);
  static const Color onJourneyRed = Color(0xFF7F1D1D);

  /// Deeper red for gradient tails and filled failure surfaces.
  static const Color journeyRedStrong = Color(0xFFB91C1C); // Red 700

  // Slate — completed, inactive history, dimmed states
  static const Color journeySlate = Color(0xFF64748B);
  static const Color journeySlateLight = Color(0xFFF1F5F9);
  static const Color onJourneySlate = Color(0xFF1E293B);

  /// Star/rating gold, and deliberately not [journeyAmber]: a rating is not an
  /// "attention needed" state, and the two have to stay independently tunable.
  /// Matches `CaptainColors.rating`, so a star means the same thing in both
  /// apps. Star icons previously used a mix of `Colors.amber` (`#FFC107`) and
  /// a bare `#F59E0B` depending on the screen.
  static const Color rating = Color(0xFFF59E0B); // Amber 500

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

  // A free seat in dark mode is the brand container one step down — dark
  // enough to stay a surface, blue enough to read as "selectable" next to the
  // neutral grey of a seat that is not.
  static const Color _darkSeatAvailable = Color(0xFF17233F);
  static const Color _darkSeatAvailableBorder = AppDarkColors.primaryContainer;
  static const Color _darkOnSeatAvailable = AppDarkColors.primaryAccent;

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
  //
  // All of these forward to [AppDarkColors]. The mapping is by *role*, not by
  // nearest hex: `surfaceSubtle` is the tier below a card in both palettes, so
  // it maps to [AppDarkColors.surfaceLow] even though the grey it replaced
  // (`#1F2937`) is numerically closer to `surfaceRaised`.
  static const Color _darkBackground = AppDarkColors.background;
  static const Color _darkSurface = AppDarkColors.surface;
  static const Color _darkSurfaceSubtle = AppDarkColors.surfaceLow;
  static const Color _darkSurfaceMuted = AppDarkColors.surfaceHighest;
  static const Color _darkSurfaceRaised = AppDarkColors.surfaceRaised;
  static const Color _darkBorder = AppDarkColors.border;
  static const Color _darkBorderStrong = AppDarkColors.borderStrong;
  static const Color _darkTextPrimary = AppDarkColors.onSurface;
  static const Color _darkTextSecondary = AppDarkColors.onSurfaceMuted;
  static const Color _darkTextTertiary = AppDarkColors.onSurfaceFaint;

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
      _isDark(context) ? AppDarkColors.background : const Color(0xFF1E3A8A);

  static Color textPrimaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextPrimary : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextSecondary : textSecondary;

  static Color textTertiaryFor(BuildContext context) =>
      _isDark(context) ? _darkTextTertiary : textTertiary;

  /// Brand blue as **ink** — a label, an icon, a thin rule, a focus ring.
  ///
  /// This is the common case by a wide margin, which is why it keeps the short
  /// name. If you are filling a shape that will carry [textInverse] on top,
  /// you want [primaryFillFor] instead.
  static Color primaryFor(BuildContext context) =>
      _isDark(context) ? darkPrimary : primary;

  /// Brand blue as a **fill** — a solid button, a selected chip, a FAB.
  ///
  /// In light mode this is the same colour as [primaryFor]. In dark mode it is
  /// deliberately the *darker* of the two: [primaryFor] is lightened to stay
  /// readable as text on the page, and white text on that lightened tone is
  /// only ~2.4:1. The fill tone keeps white at 4.87:1.
  static Color primaryFillFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryFill : primary;

  static Color primaryContainerFor(BuildContext context) =>
      _isDark(context) ? darkPrimaryLight : primaryLight;

  /// Ink for text and icons sitting on [primaryContainerFor].
  static Color onPrimaryContainerFor(BuildContext context) => _isDark(context)
      ? AppDarkColors.onPrimaryContainer
      : const Color(0xFF1D4ED8);

  static Color seatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailable : seatAvailable;

  static Color seatAvailableBorderFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailableBorder : seatAvailableBorder;

  static Color onSeatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkOnSeatAvailable : onSeatAvailable;

  static Color shadowFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.shadow : const Color(0xFF1E293B);

  /// How opaque a shadow of [shadowFor] should be, as an alpha multiplier.
  ///
  /// Dark mode has no white page for a shadow to darken, so the near-black
  /// shadows the light theme uses at 3–6% alpha are literally invisible
  /// against a slate card. Elevation there has to be carried by a heavier,
  /// wider shadow — see [ClientElevation], which scales its alphas by this.
  static double shadowAlphaScaleFor(BuildContext context) =>
      _isDark(context) ? 5.0 : 1.0;

  // ── Journey status, resolved ───────────────────────────────────────────────
  //
  // The bare `journey*` constants are mid-tones: they clear the 3:1 non-text
  // floor against both white and slate, so a dot or an icon can use them
  // unresolved. The `*Light` constants cannot — they are near-white tints
  // (`#CFFAFE`, `#FEF3C7`, …) built to sit on a white page, and on a slate one
  // they read as a lit panel in a dark room. Anything filling a shape or
  // drawing text goes through the accessors below.

  /// The **ink** tone for a journey status — a status label, a coloured value,
  /// an icon that has to be read rather than merely noticed.
  static Color journeyCyanFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.successInk : journeyCyan;

  static Color journeyAmberFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.warningInk : journeyAmber;

  static Color journeyRedFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.dangerInk : journeyRed;

  static Color journeySlateFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onSurfaceMuted : journeySlate;

  static Color journeyPurpleFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.special : journeyPurple;

  /// Star/rating gold, lightened on dark so a filled star still reads as gold
  /// rather than as a brown smudge against slate.
  static Color ratingFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.rating : rating;

  /// The **container** tone — the tinted pill or panel a status sits inside.
  static Color journeyCyanLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.successContainer : journeyCyanLight;

  static Color journeyAmberLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.warningContainer : journeyAmberLight;

  static Color journeyRedLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.dangerContainer : journeyRedLight;

  static Color journeySlateLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.neutralContainer : journeySlateLight;

  static Color journeyPurpleLightFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.specialContainer : journeyPurpleLight;

  /// Ink for text sitting on the matching `*LightFor` container.
  static Color onJourneyCyanFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onSuccessContainer : onJourneyCyan;

  static Color onJourneyAmberFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onWarningContainer : onJourneyAmber;

  static Color onJourneyRedFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onDangerContainer : onJourneyRed;

  static Color onJourneySlateFor(BuildContext context) =>
      _isDark(context) ? AppDarkColors.onNeutralContainer : onJourneySlate;

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
    // Every tone here comes from [AppDarkColors] rather than a local hex, so a
    // badge matches the status colours used elsewhere on the same screen.
    // `departing` in particular used to label itself with `darkAccent`, a
    // violet — the one hue this palette reserves for packages — which made a
    // departing-soon trip look like a subscription.
    return switch (status) {
      ClientJourneyStatus.active => (
        bg: AppDarkColors.successContainer,
        fg: AppDarkColors.onSuccessContainer,
        label: AppDarkColors.successInk,
      ),
      ClientJourneyStatus.upcoming => (
        bg: AppDarkColors.primaryContainer,
        fg: AppDarkColors.onPrimaryContainer,
        label: AppDarkColors.primaryAccent,
      ),
      ClientJourneyStatus.departing => (
        bg: AppDarkColors.warningContainer,
        fg: AppDarkColors.onWarningContainer,
        label: AppDarkColors.warningInk,
      ),
      ClientJourneyStatus.completed => (
        bg: AppDarkColors.neutralContainer,
        fg: AppDarkColors.onNeutralContainer,
        label: AppDarkColors.onSurfaceMuted,
      ),
      ClientJourneyStatus.cancelled => (
        bg: AppDarkColors.dangerContainer,
        fg: AppDarkColors.onDangerContainer,
        label: AppDarkColors.dangerInk,
      ),
    };
  }
}

/// The five lifecycle states a trip or booking can be in from the passenger's
/// perspective. Maps to the color pairs returned by [ClientColors.journeyBadge].
enum ClientJourneyStatus { active, upcoming, departing, completed, cancelled }
