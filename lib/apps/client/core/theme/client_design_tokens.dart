import 'package:bmt_app/core/theme/tokens.dart';
import 'package:flutter/material.dart';

import 'client_colors.dart';

/// Spacing steps are numerically identical to [AppTokens]' scale (just
/// offset by one name) and delegate to it so the two never drift apart.
abstract final class ClientSpacing {
  const ClientSpacing._();

  static const double xxs = AppTokens.spaceXs;
  static const double xs = AppTokens.spaceSm;
  static const double sm = AppTokens.spaceMd;
  static const double md = AppTokens.spaceLg;
  static const double lg = AppTokens.spaceXl;
  static const double xl = AppTokens.spaceXxl;
  static const double xxl = 48;
  static const double section = 56;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(24, 16, 24, 32);
  static const EdgeInsets card = EdgeInsets.all(24);
  static const EdgeInsets panel = EdgeInsets.all(24);
}

/// Deliberately more generous than [AppTokens]' operational radius scale:
/// the client app is the discovery/booking surface, and denser dashboard
/// screens use tighter radii. Not a duplicate to reconcile — see
/// specs/002-bmt-routes-booking-ux/research.md §1.
abstract final class ClientRadius {
  const ClientRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double sheet = 32;
  static const double pill = 999;
}

/// Durations are numerically identical to [AppTokens]' motion scale and
/// delegate to it so the two never drift apart.
abstract final class ClientMotion {
  const ClientMotion._();

  static const Duration fast = AppTokens.motionFast;
  static const Duration base = AppTokens.motionBase;
  static const Duration slow = AppTokens.motionSlow;
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class ClientElevation {
  const ClientElevation._();

  static List<BoxShadow> sm(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(8),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> md(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> lg(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(16),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
