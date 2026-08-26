import 'package:flutter/material.dart';

import 'client_palette.dart';

/// The named colour surface every client widget reads.
///
/// Values come from [ClientPalette], the Dart mirror of the `EWT Rider App`
/// design file's OKLCH tokens. The `const` fields below repeat
/// `ClientPalette.light`'s literals because a field read off a const instance
/// is not itself a constant expression in Dart — they are the light palette,
/// not a second opinion about it. Prefer the `…For(context)` accessors in new
/// code: they resolve light *and* dark, the bare constants only ever answer
/// light.
abstract final class ClientColors {
  /// Primary EWT brand blue — `--primary`.
  ///
  /// Use for primary actions, active navigation, selected states, links,
  /// focused controls, and important interactive elements.
  static const Color primary = Color(0xFF004F7E);

  /// Hover state for primary interactive elements.
  static const Color primaryHover = Color(0xFF00446E);

  /// Pressed / strongest primary state — `--primary-strong`.
  static const Color primaryPressed = Color(0xFF003866);

  /// Very light brand wash for selected and highlighted elements.
  static const Color primaryLight = Color(0xFFE9F5FD);

  /// Brand container for active navigation, selected cards, informational
  /// surfaces, and soft brand highlights.
  static const Color primaryContainer = Color(0xFFD2ECFC);

  /// Muted brand blue for disabled or low-emphasis brand elements.
  static const Color primaryMuted = Color(0xFF8FBBD6);

  /// Text and icons displayed on primary blue — `--on-primary`.
  static const Color onPrimary = Color(0xFFFCFCFC);

  /// Text and icons displayed on primary containers.
  static const Color onPrimaryContainer = Color(0xFF003866);

  /// Secondary brand tone — `--primary-2`.
  ///
  /// Brand surfaces are painted flat [primary], so this is only ever a paired
  /// accent on a neutral ground. Never a competing solo brand colour, and never
  /// the second half of a two-hue fill.
  static const Color secondary = Color(0xFF00848B);

  /// Soft accent, one step lighter than [secondary].
  ///
  /// Use sparingly for secondary interactive elements. EWT stays visually
  /// centred on the primary blue.
  static const Color accent = Color(0xFF2F9CA1);

  static const Color darkPrimary = Color(0xFF39B4DD);

  /// Dark-mode fill used for primary buttons and solid interactive surfaces.
  static const Color darkPrimaryFill = Color(0xFF39B4DD);

  static const Color darkPrimaryStrong = Color(0xFF51C7F1);

  static const Color darkPrimaryLight = Color(0xFF0A3341);

  /// Keep secondary brand colour inside the brand family.
  static const Color darkSecondary = Color(0xFF53C1C7);

  /// Keep the dark theme fully aligned with the EWT identity.
  static const Color darkAccent = Color(0xFF53C1C7);

  /// The brand fill — flat [primary], not a ramp.
  ///
  /// The design draws this as `linear-gradient(135deg,--primary,--primary-2)`.
  /// The app paints one colour instead: two hues behind a single card make the
  /// same surface read as two different brands end to end, and only a flat fill
  /// has one contrast ratio against [onPrimary]. Both stops are the same colour
  /// so it renders solid while the call sites keep painting a [Gradient].
  ///
  /// Reserved for office avatars, step markers, the active-trip card and the
  /// nav indicator. Avoid it on standard buttons, KPI cards, tables, status
  /// badges and list rows.
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF004F7E), Color(0xFF004F7E)],
  );

  static const Gradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF39B4DD), Color(0xFF39B4DD)],
  );

  /// The tall page header — flat, for the same reason as [primaryGradient].
  ///
  /// Light mode is the brand blue itself. Dark mode keeps a deep blue rather
  /// than the dark [darkPrimary], which is a bright cyan that cannot carry
  /// near-white hero text.
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF004F7E), Color(0xFF004F7E)],
  );

  static const Gradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF00244D), Color(0xFF00244D)],
  );

  /// Text and icons on the home hero — `--home-hero-text`.
  static const Color onHero = Color(0xFFF3F5F8);

  /// Active trip — the brand blue, per the design's live-trip card.
  static const Color journeyCyan = Color(0xFF004F7E);

  /// Soft brand background for active trip badges.
  static const Color journeyCyanLight = Color(0xFFE9F5FD);

  /// Text and icon colour on active trip surfaces.
  static const Color onJourneyCyan = Color(0xFF003866);

  /// Strong brand blue used for active trip indicators and filled surfaces.
  static const Color journeyCyanStrong = Color(0xFF003866);

  /// Amber is reserved for attention-required states — `--warning`.
  static const Color journeyAmber = Color(0xFFA75D00);

  /// Soft amber background — `--warning-bg`.
  static const Color journeyAmberLight = Color(0xFFFFE5C0);

  /// Text and icon colour on amber surfaces.
  static const Color onJourneyAmber = Color(0xFF7A4400);

  /// Strong amber for emphasis.
  static const Color journeyAmberStrong = Color(0xFF8C4E00);

  /// Red is reserved for errors, cancellation, and destructive states.
  static const Color journeyRed = Color(0xFFB32228);

  /// Soft red background — `--danger-bg`.
  static const Color journeyRedLight = Color(0xFFFFDFDA);

  /// Text and icon colour on red surfaces.
  static const Color onJourneyRed = Color(0xFF8A181D);

  /// Strong red for destructive actions and important error indicators.
  static const Color journeyRedStrong = Color(0xFF991C22);

  /// Green — `--success`. Confirmed payments, live signal, completed stops.
  static const Color journeyGreen = Color(0xFF137738);

  /// Soft green background — `--success-bg`.
  static const Color journeyGreenLight = Color(0xFFD5F5DA);

  /// Text and icon colour on green surfaces.
  static const Color onJourneyGreen = Color(0xFF0D5628);

  /// Neutral for completed trips and historical states — `--text-muted`.
  static const Color journeySlate = Color(0xFF67635D);

  /// Soft neutral background — `--surface-2`.
  static const Color journeySlateLight = Color(0xFFF0EEEB);

  /// Text and icon colour on neutral surfaces.
  static const Color onJourneySlate = Color(0xFF4A4741);

  /// Gold is reserved exclusively for ratings and stars.
  ///
  /// Do not use this colour for warnings.
  static const Color rating = Color(0xFFE2A520);

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color journeyPurple = primary;

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color journeyPurpleLight = primaryLight;

  @Deprecated('Purple is no longer part of the EWT color system.')
  static const Color onJourneyPurple = onPrimaryContainer;

  /// Available seat background.
  static const Color seatAvailable = Color(0xFFF0EEEB);

  /// Available seat border.
  static const Color seatAvailableBorder = Color(0xFFE0DDDA);

  /// Text and icon colour for available seats.
  static const Color onSeatAvailable = Color(0xFF201C18);

  static const Color _darkSeatAvailable = Color(0xFF24272B);

  static const Color _darkSeatAvailableBorder = Color(0xFF303338);

  static const Color _darkOnSeatAvailable = Color(0xFFE6E8EA);

  /// Main text colour — `--text`.
  static const Color textPrimary = Color(0xFF201C18);

  /// Secondary text colour — `--text-muted`.
  static const Color textSecondary = Color(0xFF67635D);

  /// Supporting / metadata text. The design uses one muted step; this sits a
  /// hair lighter so three-level rows still separate.
  static const Color textTertiary = Color(0xFF7C7871);

  /// Disabled text.
  static const Color textDisabled = Color(0xFF95928D);

  /// Text displayed on dark or primary surfaces.
  static const Color textInverse = Color(0xFFFCFCFC);

  /// Main page background — `--bg`.
  static const Color background = Color(0xFFFAF8F5);

  /// Main card and elevated surface — `--surface`.
  static const Color surface = Color(0xFFFEFDFC);

  /// Subtle page and section surface.
  static const Color surfaceSubtle = Color(0xFFF5F3F0);

  /// Muted surface used for inputs, chips and inert fills — `--surface-2`.
  static const Color surfaceMuted = Color(0xFFF0EEEB);

  /// Raised cards and interactive surfaces.
  static const Color surfaceRaised = Color(0xFFFEFDFC);

  /// Default hairline — `--border`.
  static const Color border = Color(0xFFE0DDDA);

  /// Strong border for inputs and emphasised separators.
  static const Color borderStrong = Color(0xFFCECAC5);

  static ClientPalette _p(BuildContext context) => ClientPalette.of(context);

  static Color surfaceFor(BuildContext context) => _p(context).surface;

  static Color backgroundFor(BuildContext context) => _p(context).bg;

  static Color surfaceSubtleFor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF131518) : surfaceSubtle;

  static Color surfaceMutedFor(BuildContext context) => _p(context).surface2;

  static Color surfaceRaisedFor(BuildContext context) => _p(context).surface;

  static Color borderFor(BuildContext context) => _p(context).border;

  static Color borderStrongFor(BuildContext context) =>
      _p(context).borderStrong;

  static Gradient primaryGradientFor(BuildContext context) =>
      _p(context).brandGradient;

  static Gradient heroGradientFor(BuildContext context) =>
      _p(context).heroGradient;

  /// First colour of the hero gradient.
  static Color heroTopFor(BuildContext context) => _p(context).heroTop;

  /// Text and icons drawn on the hero gradient.
  static Color onHeroFor(BuildContext context) => _p(context).heroText;

  static Color textPrimaryFor(BuildContext context) => _p(context).text;

  static Color textSecondaryFor(BuildContext context) => _p(context).textMuted;

  static Color textTertiaryFor(BuildContext context) =>
      _isDark(context) ? _p(context).textMuted : textTertiary;

  static Color textDisabledFor(BuildContext context) =>
      _p(context).textDisabled;

  /// Brand blue used as text, icon, border, focus ring, or indicator.
  static Color primaryFor(BuildContext context) => _p(context).primary;

  /// Brand blue used as a solid fill.
  static Color primaryFillFor(BuildContext context) => _p(context).primary;

  /// The pressed / strongest step of the brand ramp.
  static Color primaryStrongFor(BuildContext context) =>
      _p(context).primaryStrong;

  /// Text and icons on a filled brand surface.
  static Color onPrimaryFor(BuildContext context) => _p(context).onPrimary;

  /// The paired teal accent. Brand fills use [primaryFillFor], not this.
  static Color secondaryFor(BuildContext context) => _p(context).primary2;

  /// `--primary-tint` — the 12%/18% wash behind brand icon squares.
  static Color primaryTintFor(BuildContext context) => _p(context).primaryTint;

  /// Soft brand container.
  static Color primaryContainerFor(BuildContext context) =>
      _p(context).primaryContainer;

  /// Text and icons displayed on the brand container.
  static Color onPrimaryContainerFor(BuildContext context) =>
      _p(context).onPrimaryContainer;

  static Color seatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailable : seatAvailable;

  static Color seatAvailableBorderFor(BuildContext context) =>
      _isDark(context) ? _darkSeatAvailableBorder : seatAvailableBorder;

  static Color onSeatAvailableFor(BuildContext context) =>
      _isDark(context) ? _darkOnSeatAvailable : onSeatAvailable;

  static Color shadowFor(BuildContext context) => _p(context).shadow;

  /// Shadow opacity scale.
  ///
  /// Dark mode requires stronger shadows to maintain visual separation
  /// between surfaces — the design declares a much heavier `--shadow` there.
  static double shadowAlphaScaleFor(BuildContext context) =>
      _p(context).shadowAlphaScale;

  /// Active trip — the brand blue, not a separate cyan.
  static Color journeyCyanFor(BuildContext context) => _p(context).primary;

  /// Departing soon / attention required.
  static Color journeyAmberFor(BuildContext context) => _p(context).warning;

  /// Cancelled / error.
  static Color journeyRedFor(BuildContext context) => _p(context).danger;

  /// Confirmed / live / completed-step green.
  static Color journeyGreenFor(BuildContext context) => _p(context).success;

  /// Completed / inactive.
  static Color journeySlateFor(BuildContext context) => _p(context).neutral;

  /// Purple has been removed from the EWT theme.
  ///
  /// Kept as a compatibility alias only.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color journeyPurpleFor(BuildContext context) => primaryFor(context);

  static Color journeyCyanLightFor(BuildContext context) =>
      _p(context).primaryContainer;

  static Color journeyAmberLightFor(BuildContext context) =>
      _p(context).warningBg;

  static Color journeyRedLightFor(BuildContext context) => _p(context).dangerBg;

  static Color journeyGreenLightFor(BuildContext context) =>
      _p(context).successBg;

  static Color journeySlateLightFor(BuildContext context) =>
      _p(context).neutralBg;

  /// Purple has been removed from the EWT theme.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color journeyPurpleLightFor(BuildContext context) =>
      primaryContainerFor(context);

  static Color onJourneyCyanFor(BuildContext context) =>
      _p(context).onPrimaryContainer;

  static Color onJourneyAmberFor(BuildContext context) =>
      _isDark(context) ? _p(context).warning : onJourneyAmber;

  static Color onJourneyRedFor(BuildContext context) =>
      _isDark(context) ? _p(context).danger : onJourneyRed;

  static Color onJourneyGreenFor(BuildContext context) =>
      _isDark(context) ? _p(context).success : onJourneyGreen;

  static Color onJourneySlateFor(BuildContext context) =>
      _isDark(context) ? _p(context).textMuted : onJourneySlate;

  /// Purple has been removed from the EWT theme.
  @Deprecated('Purple is no longer part of the EWT color system.')
  static Color onJourneyPurpleFor(BuildContext context) =>
      onPrimaryContainerFor(context);

  static Color ratingFor(BuildContext context) => _p(context).rating;

  static ({Color bg, Color fg, Color label}) journeyBadge(
    ClientJourneyStatus status,
  ) => _badgeFrom(ClientPalette.light, status);

  static ({Color bg, Color fg, Color label}) journeyBadgeFor(
    BuildContext context,
    ClientJourneyStatus status,
  ) => _badgeFrom(_p(context), status);

  /// The design's badge recipe: the status ink on its own tinted background,
  /// with the same ink doubling as the dot colour.
  static ({Color bg, Color fg, Color label}) _badgeFrom(
    ClientPalette p,
    ClientJourneyStatus status,
  ) {
    return switch (status) {
      ClientJourneyStatus.active => (
        bg: p.successBg,
        fg: p.success,
        label: p.success,
      ),
      ClientJourneyStatus.upcoming => (
        bg: p.primaryContainer,
        fg: p.onPrimaryContainer,
        label: p.primary,
      ),
      ClientJourneyStatus.departing => (
        bg: p.warningBg,
        fg: p.warning,
        label: p.warning,
      ),
      ClientJourneyStatus.completed => (
        bg: p.neutralBg,
        fg: p.neutral,
        label: p.neutral,
      ),
      ClientJourneyStatus.cancelled => (
        bg: p.dangerBg,
        fg: p.danger,
        label: p.danger,
      ),
    };
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

enum ClientJourneyStatus { active, upcoming, departing, completed, cancelled }
