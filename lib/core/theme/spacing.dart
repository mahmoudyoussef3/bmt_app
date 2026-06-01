import 'package:flutter/material.dart';

/// Shared spacing tokens for consistent layout across the app.
class AppSpacing {
  AppSpacing._();

  static const double xSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xLarge = 20.0;

  static const EdgeInsets card = EdgeInsets.all(medium);
  static const EdgeInsets cardTight = EdgeInsets.all(small);
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );
  static const EdgeInsets formField = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}
