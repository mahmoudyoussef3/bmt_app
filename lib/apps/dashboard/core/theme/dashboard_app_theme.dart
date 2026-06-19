import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bmt_app/core/theme/app_theme.dart';

/// Dashboard-scoped theme: the shared [AppTheme] with Cairo typography applied.
///
/// Defining the override here (instead of editing [AppTheme]) keeps the client
/// and driver apps on their existing font while the operations dashboard gets a
/// native, highly readable Arabic typeface.
class DashboardAppTheme {
  DashboardAppTheme._();

  static ThemeData light() => _withCairo(AppTheme.lightTheme());

  static ThemeData dark() => _withCairo(AppTheme.darkTheme());

  static ThemeData _withCairo(ThemeData base) {
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.cairoTextTheme(base.primaryTextTheme),
    );
  }
}
