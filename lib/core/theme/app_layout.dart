import 'package:flutter/material.dart';

import 'tokens.dart';

/// Unified layout tokens for the Client App (spacing, radius, insets).
class AppLayout {
  AppLayout._();

  static const double spaceXs = AppTokens.spaceXs;
  static const double spaceSm = AppTokens.spaceSm;
  static const double spaceMd = AppTokens.spaceMd;
  static const double spaceLg = AppTokens.spaceLg;
  static const double spaceXl = AppTokens.spaceXl;
  static const double spaceXxl = AppTokens.spaceXxl;

  static const double radiusSm = AppTokens.radiusSmall;
  static const double radiusMd = AppTokens.radius;
  static const double radiusLg = AppTokens.radiusLarge;
  static const double radiusXl = AppTokens.radiusSheet;

  static BorderRadius get borderRadiusCard => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusButton => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusSheet =>
      const BorderRadius.vertical(top: Radius.circular(radiusXl));

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: spaceLg,
  );
  static const EdgeInsets pagePaddingWithTop = EdgeInsets.fromLTRB(
    spaceLg,
    spaceMd,
    spaceLg,
    spaceXl,
  );

  static const double breakpointMobile = 600; 
  static const double breakpointTablet = 1024; 
  
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
