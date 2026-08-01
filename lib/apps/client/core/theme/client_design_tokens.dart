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

/// The three lift levels a client surface can sit at.
///
/// The alphas below are light-mode values and are scaled by
/// [ClientColors.shadowAlphaScaleFor] before use. A shadow works by darkening
/// what is behind it, so an 8/255 near-black over a white page is a visible
/// edge while the same shadow over a slate page is nothing at all — dark mode
/// needs several times the opacity to produce the same separation.
abstract final class ClientElevation {
  const ClientElevation._();

  static List<BoxShadow> sm(BuildContext context) =>
      _shadow(context, alpha: 8, blur: 16, dy: 4);

  static List<BoxShadow> md(BuildContext context) =>
      _shadow(context, alpha: 12, blur: 24, dy: 8);

  static List<BoxShadow> lg(BuildContext context) =>
      _shadow(context, alpha: 16, blur: 40, dy: 16);

  static List<BoxShadow> _shadow(
    BuildContext context, {
    required int alpha,
    required double blur,
    required double dy,
  }) {
    final scaled = (alpha * ClientColors.shadowAlphaScaleFor(context))
        .round()
        .clamp(0, 255);
    return [
      BoxShadow(
        color: ClientColors.shadowFor(context).withAlpha(scaled),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }
}
