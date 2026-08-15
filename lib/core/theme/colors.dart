import 'package:flutter/material.dart';

import 'app_dark_colors.dart';
import 'app_light_colors.dart';

/// Centralized, semantic color palette used across the app.
///
/// **Neither half of this class is defined here any more.** Every light
/// constant forwards to [AppLightColors] and every `*Dark` constant to
/// [AppDarkColors] — the two palettes all three apps are drawn in. The aliases
/// stay so existing call sites keep compiling, but new code should read those
/// classes (or, better, the [ColorScheme]) directly.
///
/// The light half used to carry its own values, and they were the odd ones out:
/// a warm cream page (`#FAFAF5`) under cards that the client and captain apps
/// painted on cool slate, an orange `accent` that appeared in no other app, and
/// a `secondary` cyan a shade off the one the journey palette uses. Forwarding
/// is what stops that drifting back.
class AppColors {
  AppColors._();

  static const Color primary = AppLightColors.primary;
  static const Color primaryForeground = AppLightColors.onPrimary;

  /// The positive/"confirmed" role. Cyan, not the old `#06B6D4`: the whole
  /// system keeps success inside the brand's blue family.
  static const Color secondary = AppLightColors.success;
  static const Color secondaryForeground = AppLightColors.onFilled;

  /// Was an orange (`#FB923C`) that existed nowhere else in the product. The
  /// tertiary accent is the violet the client app reserves for packages and
  /// subscriptions.
  static const Color accent = AppLightColors.special;
  static const Color accentForeground = AppLightColors.onFilled;

  static const Color background = AppLightColors.background;
  static const Color card = AppLightColors.surface;
  static const Color popover = AppLightColors.surface;

  static const Color foreground = AppLightColors.onSurface;
  static const Color cardForeground = AppLightColors.onSurface;
  static const Color popoverForeground = AppLightColors.onSurface;

  static const Color muted = AppLightColors.surfaceHighest;
  static const Color mutedForeground = AppLightColors.onSurfaceMuted;
  static const Color border = AppLightColors.border;
  static const Color input = AppLightColors.surface;

  static const Color destructive = AppLightColors.danger;
  static const Color destructiveForeground = AppLightColors.onDanger;

  static const Color ring = AppLightColors.primaryAccent;

  static const Color primaryDark = AppDarkColors.primary;
  static const Color primaryForegroundDark = AppDarkColors.onPrimary;

  static const Color secondaryDark = AppDarkColors.successInk;
  static const Color secondaryForegroundDark = AppDarkColors.background;

  static const Color accentDark = AppDarkColors.primaryAccent;
  static const Color accentForegroundDark = AppDarkColors.background;

  static const Color backgroundDark = AppDarkColors.background;
  static const Color cardDark = AppDarkColors.surface;
  static const Color popoverDark = AppDarkColors.surface;

  static const Color foregroundDark = AppDarkColors.onSurface;
  static const Color mutedDark = AppDarkColors.surfaceHighest;
  static const Color mutedForegroundDark = AppDarkColors.onSurfaceMuted;
  static const Color borderDark = AppDarkColors.border;
  static const Color inputDark = AppDarkColors.surfaceHighest;

  static const Color destructiveDark = AppDarkColors.danger;
  static const Color ringDark = AppDarkColors.primaryAccent;
}

/// Semantic status color pairs — all WCAG AA 4.5:1 compliant on their own
/// container. Use [container] as chip background, [onContainer] as chip
/// text/icon color.
///
/// These are the **light-mode** halves of the six roles and now forward to
/// [AppLightColors], so a status chip in the dashboard is the same colour as
/// the same status in the client and captain apps. The dark halves live in
/// [AppDarkColors]; [AppStatusStyle] resolves between them.
///
/// Success was green here (`#DCFCE7` / `#166534`) while both mobile apps had
/// already moved the positive role to cyan. That is a semantic split, not just
/// a visual one — the same "approved" badge rendered green on the dashboard and
/// cyan in the app it was approving something for.
class AppStatusColors {
  AppStatusColors._();

  static const Color successContainer = AppLightColors.successContainer;
  static const Color onSuccessContainer = AppLightColors.onSuccessContainer;

  static const Color warningContainer = AppLightColors.warningContainer;
  static const Color onWarningContainer = AppLightColors.onWarningContainer;

  static const Color errorContainer = AppLightColors.dangerContainer;
  static const Color onErrorContainer = AppLightColors.onDangerContainer;

  static const Color infoContainer = AppLightColors.infoContainer;
  static const Color onInfoContainer = AppLightColors.onInfoContainer;

  static const Color neutralContainer = AppLightColors.neutralContainer;
  static const Color onNeutralContainer = AppLightColors.onNeutralContainer;

  static const Color specialContainer = AppLightColors.specialContainer;
  static const Color onSpecialContainer = AppLightColors.onSpecialContainer;
}

/// The six status roles, so a caller can ask for one instead of naming a colour.
enum AppStatusTone { success, warning, error, info, neutral, special }

/// A status colour set resolved for the current brightness.
///
/// The constants in [AppStatusColors] are light-mode tints — a `#DCFCE7` chip
/// on a `#0F172A` page is a lit panel in a dark room. This resolves the same six
/// roles against the theme, so a status chip is legible in both modes without
/// every call site writing its own `isDark` branch.
///
/// [tint] is the chip/container fill, [ink] the text and icon on it, and
/// [accent] the standalone mark — a dot, a border, a bare status label with no
/// container behind it.
///
/// [fill] / [onFill] are the fourth and fifth members, and they exist because
/// call sites kept reaching for the wrong one. A semantic **filled button** —
/// the green "approve payment", the red "reject" — was being drawn as
/// `backgroundColor: ink, foregroundColor: Colors.white`, which is a light-mode
/// reading of `ink`: in dark mode `ink` is the *pale* half of the pair
/// (`#A5F3FC` for success, `#FECACA` for error), so those buttons rendered as a
/// pastel slab with white text on it at roughly **1.2:1**. Unreadable, and the
/// approve button on the bookings queue is the most-pressed control in the
/// product.
///
/// Each pair below is the one the [ColorScheme] already declares for the same
/// role (dark `secondary`/`onSecondary` is exactly `successInk` on
/// `background`); naming them by *tone* is what lets a button ask for "the
/// positive fill" without hard-coding which Material slot that happens to be.
@immutable
class AppStatusStyle {
  const AppStatusStyle({
    required this.tint,
    required this.ink,
    required this.accent,
    required this.fill,
    required this.onFill,
  });

  final Color tint;
  final Color ink;
  final Color accent;

  /// A saturated, *filled* surface for this tone — a semantic primary button.
  /// Always paired with [onFill], never with a hard-coded white.
  final Color fill;

  /// Ink on [fill]. AA on it in both themes.
  final Color onFill;

  static AppStatusStyle of(BuildContext context, AppStatusTone tone) {
    return resolve(Theme.of(context).brightness, tone);
  }

  static AppStatusStyle resolve(Brightness brightness, AppStatusTone tone) {
    return brightness == Brightness.dark ? _dark(tone) : _light(tone);
  }

  /// Both themes fill with the tone's own **fill** constant; only the ink on it
  /// differs. Cyan and amber are light enough that white on them fails (`#0EA5E9`
  /// under white is 2.7:1) so dark mode inks them with the page colour instead —
  /// 6.5:1 and 8.4:1. Red and blue are dark enough to keep white in both themes,
  /// which is also what `ColorScheme.error` and `.primary` already do.
  ///
  /// Filling with the *ink* tone was the alternative, and it is what the first
  /// version of this did; a `#22D3EE` approve button is legible but reads as
  /// neon beside the same button's deep teal in light mode. One constant per
  /// tone keeps the two themes the same design at two brightnesses.
  static AppStatusStyle _dark(AppStatusTone tone) => switch (tone) {
    AppStatusTone.success => const AppStatusStyle(
      tint: AppDarkColors.successContainer,
      ink: AppDarkColors.onSuccessContainer,
      accent: AppDarkColors.successInk,
      fill: AppDarkColors.success,
      onFill: AppDarkColors.background,
    ),
    AppStatusTone.warning => const AppStatusStyle(
      tint: AppDarkColors.warningContainer,
      ink: AppDarkColors.onWarningContainer,
      accent: AppDarkColors.warningInk,
      fill: AppDarkColors.warning,
      onFill: AppDarkColors.background,
    ),
    AppStatusTone.error => const AppStatusStyle(
      tint: AppDarkColors.dangerContainer,
      ink: AppDarkColors.onDangerContainer,
      accent: AppDarkColors.dangerInk,
      fill: AppDarkColors.danger,
      onFill: AppDarkColors.onDanger,
    ),
    AppStatusTone.info => const AppStatusStyle(
      tint: AppDarkColors.infoContainer,
      ink: AppDarkColors.onInfoContainer,
      accent: AppDarkColors.primaryAccent,
      fill: AppDarkColors.primary,
      onFill: AppDarkColors.onPrimary,
    ),
    AppStatusTone.neutral => const AppStatusStyle(
      tint: AppDarkColors.neutralContainer,
      ink: AppDarkColors.onNeutralContainer,
      accent: AppDarkColors.onSurfaceMuted,
      fill: AppDarkColors.surfaceHighest,
      onFill: AppDarkColors.onSurface,
    ),
    AppStatusTone.special => const AppStatusStyle(
      tint: AppDarkColors.specialContainer,
      ink: AppDarkColors.onSpecialContainer,
      accent: AppDarkColors.special,
      fill: AppDarkColors.special,
      onFill: AppDarkColors.background,
    ),
  };

  /// The light halves. [accent] is the mid-weight `*Ink` tone rather than the
  /// container's own ink: a standalone dot or bare label has the page behind
  /// it, not the container, so `#164E63`-on-white reads as near-black text
  /// rather than as a status.
  static AppStatusStyle _light(AppStatusTone tone) => switch (tone) {
    AppStatusTone.success => const AppStatusStyle(
      tint: AppLightColors.successContainer,
      ink: AppLightColors.onSuccessContainer,
      accent: AppLightColors.successInk,
      fill: AppLightColors.success,
      onFill: AppLightColors.onFilled,
    ),
    AppStatusTone.warning => const AppStatusStyle(
      tint: AppLightColors.warningContainer,
      ink: AppLightColors.onWarningContainer,
      accent: AppLightColors.warningInk,
      fill: AppLightColors.warning,
      onFill: AppLightColors.onFilled,
    ),
    AppStatusTone.error => const AppStatusStyle(
      tint: AppLightColors.dangerContainer,
      ink: AppLightColors.onDangerContainer,
      accent: AppLightColors.dangerInk,
      fill: AppLightColors.danger,
      onFill: AppLightColors.onDanger,
    ),
    AppStatusTone.info => const AppStatusStyle(
      tint: AppLightColors.infoContainer,
      ink: AppLightColors.onInfoContainer,
      accent: AppLightColors.primaryAccent,
      fill: AppLightColors.primary,
      onFill: AppLightColors.onPrimary,
    ),
    AppStatusTone.neutral => const AppStatusStyle(
      tint: AppLightColors.neutralContainer,
      ink: AppLightColors.onNeutralContainer,
      accent: AppLightColors.onSurfaceMuted,
      fill: AppLightColors.surfaceHighest,
      onFill: AppLightColors.onSurface,
    ),
    AppStatusTone.special => const AppStatusStyle(
      tint: AppLightColors.specialContainer,
      ink: AppLightColors.onSpecialContainer,
      accent: AppLightColors.special,
      fill: AppLightColors.special,
      onFill: AppLightColors.onFilled,
    ),
  };
}

/// The unified light scheme, built from [AppLightColors].
///
/// Stated role for role against [darkColorSchemeFromPalette] so the two themes
/// are the same structure at two brightnesses. The old version declared only
/// fourteen roles and let the rest fall back, which is where light mode picked
/// up its Material defaults: an unset `onSurfaceVariant` resolved to
/// `onSurface`, collapsing secondary text to full black, and an unset
/// `errorContainer` resolved to `error`, so every "container" surface came back
/// saturated red. The dark theme had already been fixed for exactly this; this
/// is the same fix on the other half.
ColorScheme lightColorSchemeFromPalette() {
  return const ColorScheme(
    brightness: Brightness.light,

    primary: AppLightColors.primary,
    onPrimary: AppLightColors.onPrimary,
    primaryContainer: AppLightColors.primaryContainer,
    onPrimaryContainer: AppLightColors.onPrimaryContainer,

    secondary: AppLightColors.success,
    onSecondary: AppLightColors.onFilled,
    secondaryContainer: AppLightColors.successContainer,
    onSecondaryContainer: AppLightColors.onSuccessContainer,

    tertiary: AppLightColors.special,
    onTertiary: AppLightColors.onFilled,
    tertiaryContainer: AppLightColors.specialContainer,
    onTertiaryContainer: AppLightColors.onSpecialContainer,

    error: AppLightColors.danger,
    onError: AppLightColors.onDanger,
    errorContainer: AppLightColors.dangerContainer,
    onErrorContainer: AppLightColors.onDangerContainer,

    surface: AppLightColors.surface,
    onSurface: AppLightColors.onSurface,
    onSurfaceVariant: AppLightColors.onSurfaceMuted,
    surfaceDim: AppLightColors.canvas,
    surfaceBright: AppLightColors.surface,
    surfaceContainerLowest: AppLightColors.background,
    surfaceContainerLow: AppLightColors.surfaceLow,
    surfaceContainer: AppLightColors.surface,
    surfaceContainerHigh: AppLightColors.surfaceRaised,
    surfaceContainerHighest: AppLightColors.surfaceHighest,

    outline: AppLightColors.border,
    outlineVariant: AppLightColors.borderSubtle,

    shadow: AppLightColors.shadow,
    scrim: AppLightColors.scrim,

    surfaceTint: Colors.transparent,

    inverseSurface: AppLightColors.onSurface,
    onInverseSurface: AppLightColors.surface,
    inversePrimary: AppDarkColors.primaryAccent,
  );
}

/// The unified dark scheme, built from [AppDarkColors].
///
/// Every Material 3 role is stated rather than left to fall back. That matters
/// more than it sounds: an unset `onSurfaceVariant` resolves to `onSurface`, so
/// the ~320 call sites using it for secondary text were rendering at full white
/// and the type hierarchy collapsed; an unset `errorContainer` resolves to
/// `error`, so "container" surfaces came back as solid saturated red. Both are
/// now real tones.
///
/// `surfaceContainerLowest` is the page background because that is what the
/// codebase already uses it for (`scaffoldBackgroundColor`, and the pages that
/// set their own). The ladder climbs from there — see [AppDarkColors].
ColorScheme darkColorSchemeFromPalette() {
  return const ColorScheme(
    brightness: Brightness.dark,

    primary: AppDarkColors.primary,
    onPrimary: AppDarkColors.onPrimary,
    primaryContainer: AppDarkColors.primaryContainer,
    onPrimaryContainer: AppDarkColors.onPrimaryContainer,

    secondary: AppDarkColors.successInk,
    onSecondary: AppDarkColors.background,
    secondaryContainer: AppDarkColors.successContainer,
    onSecondaryContainer: AppDarkColors.onSuccessContainer,

    tertiary: AppDarkColors.special,
    onTertiary: AppDarkColors.background,
    tertiaryContainer: AppDarkColors.specialContainer,
    onTertiaryContainer: AppDarkColors.onSpecialContainer,

    error: AppDarkColors.danger,
    onError: AppDarkColors.onDanger,
    errorContainer: AppDarkColors.dangerContainer,
    onErrorContainer: AppDarkColors.onDangerContainer,

    surface: AppDarkColors.surface,
    onSurface: AppDarkColors.onSurface,
    onSurfaceVariant: AppDarkColors.onSurfaceMuted,
    surfaceDim: AppDarkColors.canvas,
    surfaceBright: AppDarkColors.surfaceHighest,
    surfaceContainerLowest: AppDarkColors.background,
    surfaceContainerLow: AppDarkColors.surfaceLow,
    surfaceContainer: AppDarkColors.surface,
    surfaceContainerHigh: AppDarkColors.surfaceRaised,
    surfaceContainerHighest: AppDarkColors.surfaceHighest,

    outline: AppDarkColors.border,
    outlineVariant: AppDarkColors.borderSubtle,

    shadow: AppDarkColors.shadow,
    scrim: AppDarkColors.scrim,

    surfaceTint: Colors.transparent,

    inverseSurface: AppDarkColors.onSurface,
    onInverseSurface: AppDarkColors.background,
    inversePrimary: AppDarkColors.primary,
  );
}
