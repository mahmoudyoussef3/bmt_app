import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry shared between the loaded profile header and its loading skeleton.
///
/// The two must agree or the load→loaded transition visibly jumps, which is
/// exactly what happened while each file carried its own copy of the height.
class DriverProfileMetrics {
  DriverProfileMetrics._();

  /// Height of the identity bar, excluding the status bar above it.
  ///
  /// The header was a 176-tall gradient hero that stacked the avatar and name
  /// under a screen title, and most of that height was empty brand colour. It
  /// now carries the same identity on a single toolbar row, so it only has to
  /// be as tall as that row — plus whatever the user's text scale asks for.
  static double toolbarHeight(BuildContext context) =>
      math.max(kToolbarHeight, MediaQuery.textScalerOf(context).scale(64));

  /// Diameter of the header avatar. Shared so the skeleton's placeholder circle
  /// can't drift away from the real one.
  static const double avatarSize = 38;
}
