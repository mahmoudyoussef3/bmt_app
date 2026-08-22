import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/app_theme.dart';

/// Dashboard-scoped theme: the shared [AppTheme] with Cairo typography applied.
///
/// Defining the override here (instead of editing [AppTheme]) keeps the client
/// and driver apps on their existing font while the operations dashboard gets a
/// native, highly readable Arabic typeface.
class DashboardAppTheme {
  DashboardAppTheme._();

  /// Light mode gets its own card treatment — [AppSurfaceStyle.dashboardLight]
  /// — rather than the flatter one below. [AppSurfaceStyle.flat] reads as bare
  /// and washed out against this console's near-white page (see the type's own
  /// doc for why); the dashboard variant is tuned for a dense admin console
  /// rather than borrowed from the client app's mobile card style. Dark mode
  /// keeps the flat look untouched.
  static ThemeData light() =>
      _withCairo(AppTheme.lightTheme(), AppSurfaceStyle.dashboardLight);

  static ThemeData dark() => _withCairo(AppTheme.darkTheme(), AppSurfaceStyle.flat);

  static ThemeData _withCairo(
    ThemeData base,
    AppSurfaceStyle Function(ColorScheme) surfaceStyle,
  ) {
    final scheme = base.colorScheme;
    final textTheme = _dashboardTextTheme(scheme);
    return base.copyWith(
      extensions: [
        ...base.extensions.values.where((extension) {
          return extension is! AppSurfaceStyle;
        }),
        surfaceStyle(scheme),
      ],
      appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }

  static TextTheme _dashboardTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.cairoTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      decorationColor: scheme.onSurface,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.18,
        letterSpacing: 0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.22,
        letterSpacing: 0,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.28,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.55,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
      ),
    );
  }
}
