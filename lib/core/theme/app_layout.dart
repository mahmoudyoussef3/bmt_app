import 'package:flutter/material.dart';

import 'tokens.dart';

/// Unified layout tokens for the Client App (spacing, radius, insets).
class AppLayout {
  AppLayout._();

  // Spacing scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  // Border radius
  static const double radiusSm = AppTokens.radiusSmall;
  static const double radiusMd = AppTokens.radius;
  static const double radiusLg = AppTokens.radiusLarge;
  static const double radiusXl = 24;

  static BorderRadius get borderRadiusCard => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusButton => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusSheet =>
      const BorderRadius.vertical(top: Radius.circular(radiusXl));

  // Page layout
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: spaceLg,
  );
  static const EdgeInsets pagePaddingWithTop = EdgeInsets.fromLTRB(
    spaceLg,
    spaceMd,
    spaceLg,
    spaceXl,
  );

  // Responsive breakpoints
  static const double breakpointMobile = 600; // < 600 → mobile
  static const double breakpointTablet = 1024; // 600–1024 → tablet
  // > 1024 → desktop

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointMobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= breakpointMobile && w < breakpointTablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointTablet;

  static const double maxContentWidthTablet = 560;
  static const double maxContentWidthDesktop = 720;

  static double maxContentWidth(double screenWidth) {
    if (screenWidth >= 900) return maxContentWidthDesktop;
    if (screenWidth >= 600) return maxContentWidthTablet;
    return screenWidth;
  }
}
