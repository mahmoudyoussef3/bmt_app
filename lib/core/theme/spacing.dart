import 'package:flutter/material.dart';

import 'app_layout.dart';

/// Shared spacing tokens for consistent layout across the app.
class AppSpacing {
  AppSpacing._();

  static const double xSmall = AppLayout.spaceXs;
  static const double small = AppLayout.spaceSm;
  static const double medium = AppLayout.spaceMd;
  static const double large = AppLayout.spaceLg;
  static const double xLarge = AppLayout.spaceXl;

  static const EdgeInsets card = EdgeInsets.all(medium);
  static const EdgeInsets cardTight = EdgeInsets.all(small);
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: small,
    vertical: xSmall,
  );
  static const EdgeInsets formField = EdgeInsets.symmetric(
    horizontal: medium,
    vertical: small,
  );
}
