import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Theme-driven surface styling for [AppCard]-like surfaces (radius, border,
/// shadow). Registering an [AppSurfaceStyle] on a [ThemeData] lets one app
/// (e.g. the operations dashboard) adopt a flat, premium card look while the
/// other apps keep their existing style via [AppSurfaceStyle.legacy].
@immutable
class AppSurfaceStyle extends ThemeExtension<AppSurfaceStyle> {
  final double radius;
  final Color borderColor;
  final List<BoxShadow> shadow;

  const AppSurfaceStyle({
    required this.radius,
    required this.borderColor,
    required this.shadow,
  });

  /// Heavy legacy look — the fallback when no extension is registered, so the
  /// client and driver apps render exactly as before.
  factory AppSurfaceStyle.legacy(ColorScheme scheme) => AppSurfaceStyle(
    radius: 18,
    borderColor: scheme.outline.withAlpha(90),
    shadow: [
      BoxShadow(
        color: Colors.black.withAlpha(18),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Flat, modern look used by the operations dashboard: hairline border and a
  /// soft, low shadow instead of the heavy drop shadow.
  factory AppSurfaceStyle.flat(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return AppSurfaceStyle(
      radius: 16,
      borderColor: scheme.outline.withAlpha(dark ? 100 : 70),
      shadow: [
        BoxShadow(
          color: Colors.black.withAlpha(dark ? 32 : 10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// The operations dashboard's LIGHT-mode card look.
  ///
  /// [flat]'s hairline border plus a 10-alpha blur reads as bare on a
  /// near-white page: [background] and [surface] are only ~11 lightness units
  /// apart, so a card needs its edge to do real work that a lightness jump
  /// does for free in dark mode. Three changes carry that: the border runs at
  /// **full** opacity rather than a further-thinned alpha over an already
  /// light token — halving an already-subtle grey is how it disappeared; a
  /// **layered** shadow — a tight contact blur that draws the edge plus a
  /// soft ambient one that gives real lift, the pairing a single blur can't
  /// reproduce; and tinting both with the palette's own slate
  /// [ColorScheme.shadow] rather than raw black, which read muddy against a
  /// cool page. `spreadRadius: -2` on the ambient layer keeps the lift from
  /// bleeding sideways into whatever sits beside the card, which is what
  /// "huge shadow" actually looks like.
  factory AppSurfaceStyle.dashboardLight(ColorScheme scheme) => AppSurfaceStyle(
    radius: 16,
    borderColor: scheme.outline,
    shadow: [
      BoxShadow(
        color: scheme.shadow.withAlpha(24),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: scheme.shadow.withAlpha(36),
        blurRadius: 32,
        offset: const Offset(0, 14),
        spreadRadius: -2,
      ),
    ],
  );

  /// The EWT console redesign's card look: depth comes from the border and the
  /// surface ladder, not from lift. A 12px radius (down from [dashboardLight]'s
  /// 16) and a single 2px contact shadow replace the two-layer 32px ambient
  /// blur — see `DashboardLightColors.softShadow` for why a floating card was
  /// the wrong metaphor for a console page that is mostly cards.
  ///
  /// One factory for both brightnesses, like [flat]: [scheme] is expected to be
  /// built from `DashboardLightColors`/`DashboardDarkColors`, so `scheme.outline`
  /// and `scheme.shadow` already carry the console's own border/shadow tint.
  factory AppSurfaceStyle.ewt(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return AppSurfaceStyle(
      radius: 12,
      borderColor: scheme.outline,
      shadow: [
        BoxShadow(
          color: scheme.shadow.withAlpha(dark ? 89 : 13),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  @override
  AppSurfaceStyle copyWith({
    double? radius,
    Color? borderColor,
    List<BoxShadow>? shadow,
  }) {
    return AppSurfaceStyle(
      radius: radius ?? this.radius,
      borderColor: borderColor ?? this.borderColor,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppSurfaceStyle lerp(ThemeExtension<AppSurfaceStyle>? other, double t) {
    if (other is! AppSurfaceStyle) return this;
    return AppSurfaceStyle(
      radius: lerpDouble(radius, other.radius, t) ?? radius,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
    );
  }
}
