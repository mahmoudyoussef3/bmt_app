import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_theme.dart';

abstract final class ClientTheme {
  const ClientTheme._();

  static ThemeData light() => AppTheme.lightTheme();

  static ThemeData dark() => AppTheme.darkTheme();
}
