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
