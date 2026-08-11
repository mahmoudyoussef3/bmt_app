import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/theme/app_layout.dart';

/// Centralized spacing tokens (XS–XXL) and vertical/horizontal gaps.
class AppSpacing {
  AppSpacing._();

  static const double xs = AppLayout.spaceXs;
  static const double sm = AppLayout.spaceSm;
  static const double md = AppLayout.spaceMd;
  static const double lg = AppLayout.spaceLg;
  static const double xl = AppLayout.spaceXl;
  static const double xxl = AppLayout.spaceXxl;

  static const double xSmall = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double xLarge = xl;

  static const SizedBox hXs = SizedBox(height: xs);
  static const SizedBox hSm = SizedBox(height: sm);
  static const SizedBox hMd = SizedBox(height: md);
  static const SizedBox hLg = SizedBox(height: lg);
  static const SizedBox hXl = SizedBox(height: xl);
  static const SizedBox hXxl = SizedBox(height: xxl);

  static const SizedBox wXs = SizedBox(width: xs);
  static const SizedBox wSm = SizedBox(width: sm);
  static const SizedBox wMd = SizedBox(width: md);
  static const SizedBox wLg = SizedBox(width: lg);
  static const SizedBox wXl = SizedBox(width: xl);
}
