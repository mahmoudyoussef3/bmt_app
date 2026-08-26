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

  /// The design's phone gutter: 16 either side, with room under the last card
  /// for the floating nav island.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(16, 12, 16, 32);

  /// `padding:16px` — the design's `CARD`.
  static const EdgeInsets card = EdgeInsets.all(16);

  /// Larger panels (sheets, hero blocks) get one step more air.
  static const EdgeInsets panel = EdgeInsets.all(20);
}

/// Corner radii, taken from the `EWT Rider App` design file.
///
/// The design draws three distinct shapes and no more: fields and small rows
/// at 12, buttons and inner panels at 14–16, cards at 18–20. Denser dashboard
/// screens keep [AppTokens]' tighter scale — this is the discovery/booking
/// surface and is deliberately rounder. Not a duplicate to reconcile; see
/// specs/002-bmt-routes-booking-ux/research.md §1.
abstract final class ClientRadius {
  const ClientRadius._();

  static const double xs = 8;

  /// Inputs, chips, compact list rows.
  static const double sm = 12;

  /// Buttons, inner panels, seat tiles.
  static const double md = 16;

  /// Cards — the design's `CARD` constant.
  static const double lg = 20;

  /// Hero blocks and large media.
  static const double xl = 28;

  static const double sheet = 28;
  static const double pill = 999;

  /// The primary action's radius — `border-radius:14px` on every CTA.
  static const double control = 14;
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
/// The alphas below are the design's light-mode `--shadow` (8% of a near-black)
/// expressed on Flutter's 0–255 scale, and are multiplied by
/// [ClientColors.shadowAlphaScaleFor] before use. A shadow works by darkening
/// what is behind it, so an 8% near-black over a near-white page is a visible
/// edge while the same shadow over the dark page is nothing at all — dark mode
/// needs several times the opacity to produce the same separation, which is
/// exactly what the design's much heavier dark `--shadow` does.
abstract final class ClientElevation {
  const ClientElevation._();

  /// `0 6px 20px var(--shadow)` — list cards, office tiles, quick actions.
  static List<BoxShadow> sm(BuildContext context) =>
      _shadow(context, alpha: 20, blur: 20, dy: 6);

  /// `0 10px 28px var(--shadow)` — the design's `CARD` and hero blocks.
  static List<BoxShadow> md(BuildContext context) =>
      _shadow(context, alpha: 20, blur: 28, dy: 10);

  /// `0 14px 30px var(--shadow)` — the home header and floating chrome.
  static List<BoxShadow> lg(BuildContext context) =>
      _shadow(context, alpha: 26, blur: 30, dy: 14);

  /// `0 10px 22px var(--primary-tint)` — the coloured lift under a filled CTA,
  /// which the design tints with the brand rather than with neutral shadow.
  static List<BoxShadow> primary(BuildContext context) => [
    BoxShadow(
      color: ClientColors.primaryTintFor(context),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];

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
