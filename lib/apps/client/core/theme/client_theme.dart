import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

/// The shared [AppTheme], rendered in Cairo.
///
/// The client app is Arabic-first and the shared scale is set in Outfit, a
/// Latin-only face — so every Arabic string was falling back to a platform
/// default that differs per device. Cairo covers both scripts and is already
/// what the captain and dashboard apps use.
abstract final class ClientTheme {
  const ClientTheme._();

  static ThemeData light() =>
      AppTheme.lightTheme(textThemeBuilder: AppTextThemes.cairoTextThemeFor);

  static ThemeData dark() =>
      AppTheme.darkTheme(textThemeBuilder: AppTextThemes.cairoTextThemeFor);
}
