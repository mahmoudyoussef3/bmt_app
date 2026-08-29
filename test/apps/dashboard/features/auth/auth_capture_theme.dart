/// The [ThemeData] both signed-out capture harnesses render against.
///
/// [DashboardAppTheme] itself builds its text theme through
/// `GoogleFonts.cairoTextTheme()`, which the test binding's blocked network
/// turns into a hard failure — so this hand-builds a [ThemeData] from the same
/// [DashboardLightColors]/[DashboardDarkColors] source, restating the input,
/// button and divider themes these screens actually lean on. The palette and
/// component language are the real ones; only the glyphs differ.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/tokens.dart';

const captureFont = 'CaptureArabic';

/// Loads a real Arabic-capable face off the host so the captures show words
/// rather than tofu. A no-op where the font is missing — the capture is still
/// written, just with the default glyphs.
Future<void> loadCaptureFont() async {
  const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
  final file = File(path);
  if (!file.existsSync()) return;
  final loader = FontLoader(captureFont)
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

ThemeData themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? dashboardDarkColorScheme()
      : dashboardLightColorScheme();
  final background = dark
      ? DashboardDarkColors.background
      : DashboardLightColors.background;
  final surface = dark
      ? DashboardDarkColors.surface
      : DashboardLightColors.surface;
  final surfaceHighest = dark
      ? DashboardDarkColors.surfaceHighest
      : DashboardLightColors.surfaceHighest;
  final onSurface = dark
      ? DashboardDarkColors.onSurface
      : DashboardLightColors.onSurface;
  final onSurfaceMuted = dark
      ? DashboardDarkColors.onSurfaceMuted
      : DashboardLightColors.onSurfaceMuted;
  final onSurfaceFaint = dark
      ? DashboardDarkColors.onSurfaceFaint
      : DashboardLightColors.onSurfaceFaint;
  final border = dark
      ? DashboardDarkColors.border
      : DashboardLightColors.border;
  final primary = dark
      ? DashboardDarkColors.primary
      : DashboardLightColors.primary;
  final onPrimary = dark
      ? DashboardDarkColors.onPrimary
      : DashboardLightColors.onPrimary;
  final primaryAccent = dark
      ? DashboardDarkColors.primaryAccent
      : DashboardLightColors.primaryAccent;
  final focus = dark ? primaryAccent : DashboardLightColors.focus;
  final dangerInk = dark
      ? DashboardDarkColors.dangerInk
      : DashboardLightColors.dangerInk;
  final shadow = dark
      ? DashboardDarkColors.shadow
      : DashboardLightColors.shadow;
  final hairline = BorderSide(color: border);

  OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTokens.radius),
    borderSide: side,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: captureFont,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: scheme.surface,
    dividerColor: border,
    shadowColor: shadow,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? surfaceHighest : surface,
      border: inputBorder(hairline),
      enabledBorder: inputBorder(hairline),
      focusedBorder: inputBorder(BorderSide(color: focus, width: 2)),
      errorBorder: inputBorder(BorderSide(color: dangerInk)),
      focusedErrorBorder: inputBorder(BorderSide(color: dangerInk, width: 2)),
      hintStyle: TextStyle(color: onSurfaceFaint),
      prefixIconColor: onSurfaceMuted,
      suffixIconColor: onSurfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        disabledBackgroundColor: surfaceHighest,
        disabledForegroundColor: onSurfaceFaint,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        disabledForegroundColor: onSurfaceFaint,
        side: hairline,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
    ),
    extensions: [AppSurfaceStyle.ewt(scheme)],
  );
}
