import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';

/// The dashboard's light [ColorScheme], built from [DashboardLightColors].
///
/// Stated role for role against [dashboardDarkColorScheme], mirroring how
/// `lightColorSchemeFromPalette()`/`darkColorSchemeFromPalette()` build the
/// client/captain scheme from `AppLightColors`/`AppDarkColors` — same shape,
/// console-only palette.
ColorScheme dashboardLightColorScheme() {
  return const ColorScheme(
    brightness: Brightness.light,

    primary: DashboardLightColors.primary,
    onPrimary: DashboardLightColors.onPrimary,
    primaryContainer: DashboardLightColors.primaryContainer,
    onPrimaryContainer: DashboardLightColors.onPrimaryContainer,

    secondary: DashboardLightColors.success,
    onSecondary: DashboardLightColors.onFilled,
    secondaryContainer: DashboardLightColors.successContainer,
    onSecondaryContainer: DashboardLightColors.onSuccessContainer,

    tertiary: DashboardLightColors.special,
    onTertiary: DashboardLightColors.onFilled,
    tertiaryContainer: DashboardLightColors.specialContainer,
    onTertiaryContainer: DashboardLightColors.onSpecialContainer,

    error: DashboardLightColors.danger,
    onError: DashboardLightColors.onDanger,
    errorContainer: DashboardLightColors.dangerContainer,
    onErrorContainer: DashboardLightColors.onDangerContainer,

    surface: DashboardLightColors.surface,
    onSurface: DashboardLightColors.onSurface,
    onSurfaceVariant: DashboardLightColors.onSurfaceMuted,
    surfaceDim: DashboardLightColors.canvas,
    surfaceBright: DashboardLightColors.surface,
    surfaceContainerLowest: DashboardLightColors.background,
    surfaceContainerLow: DashboardLightColors.surfaceLow,
    surfaceContainer: DashboardLightColors.surface,
    surfaceContainerHigh: DashboardLightColors.surfaceRaised,
    surfaceContainerHighest: DashboardLightColors.surfaceHighest,

    outline: DashboardLightColors.border,
    outlineVariant: DashboardLightColors.borderSubtle,

    shadow: DashboardLightColors.shadow,
    scrim: DashboardLightColors.scrim,

    surfaceTint: Colors.transparent,

    inverseSurface: DashboardLightColors.onSurface,
    onInverseSurface: DashboardLightColors.surface,
    inversePrimary: DashboardDarkColors.primaryAccent,
  );
}

/// The dashboard's dark [ColorScheme], built from [DashboardDarkColors].
ColorScheme dashboardDarkColorScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,

    primary: DashboardDarkColors.primary,
    onPrimary: DashboardDarkColors.onPrimary,
    primaryContainer: DashboardDarkColors.primaryContainer,
    onPrimaryContainer: DashboardDarkColors.onPrimaryContainer,

    secondary: DashboardDarkColors.successInk,
    onSecondary: DashboardDarkColors.background,
    secondaryContainer: DashboardDarkColors.successContainer,
    onSecondaryContainer: DashboardDarkColors.onSuccessContainer,

    tertiary: DashboardDarkColors.special,
    onTertiary: DashboardDarkColors.background,
    tertiaryContainer: DashboardDarkColors.specialContainer,
    onTertiaryContainer: DashboardDarkColors.onSpecialContainer,

    error: DashboardDarkColors.danger,
    onError: DashboardDarkColors.onDanger,
    errorContainer: DashboardDarkColors.dangerContainer,
    onErrorContainer: DashboardDarkColors.onDangerContainer,

    surface: DashboardDarkColors.surface,
    onSurface: DashboardDarkColors.onSurface,
    onSurfaceVariant: DashboardDarkColors.onSurfaceMuted,
    surfaceDim: DashboardDarkColors.canvas,
    surfaceBright: DashboardDarkColors.surfaceHighest,
    surfaceContainerLowest: DashboardDarkColors.background,
    surfaceContainerLow: DashboardDarkColors.surfaceLow,
    surfaceContainer: DashboardDarkColors.surface,
    surfaceContainerHigh: DashboardDarkColors.surfaceRaised,
    surfaceContainerHighest: DashboardDarkColors.surfaceHighest,

    outline: DashboardDarkColors.border,
    outlineVariant: DashboardDarkColors.borderSubtle,

    shadow: DashboardDarkColors.shadow,
    scrim: DashboardDarkColors.scrim,

    surfaceTint: Colors.transparent,

    inverseSurface: DashboardDarkColors.onSurface,
    onInverseSurface: DashboardDarkColors.background,
    inversePrimary: DashboardDarkColors.primary,
  );
}
