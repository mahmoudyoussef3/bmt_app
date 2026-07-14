import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/theme/text_themes.dart';

/// Shared visual tokens for every EasyWay map surface, so tiles, route line,
/// markers and floating overlays stay in sync across Route Discovery, Route
/// Details and Live Tracking (colors, labels, shadows, pills).
class MapStyle {
  const MapStyle._();

  static Color start(BuildContext context) => AppColors.secondary;

  static Color end(BuildContext context) => Theme.of(context).colorScheme.error;

  static Color stop(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color routeLine(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Muted tone for the "remaining" half of a progress-split route line.
  static Color routeLineMuted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).colorScheme.primary.withAlpha(isDark ? 90 : 70);
  }

  /// Marker fill color by position along the ordered route.
  static Color colorFor(BuildContext context, int index, int count) {
    if (index == 0) return start(context);
    if (index == count - 1) return end(context);
    return stop(context);
  }

  /// Short badge shown inside the marker (A · B · stop number).
  static String labelFor(int index, int count) {
    if (index == 0) return 'A';
    if (index == count - 1) return 'B';
    return '${index + 1}';
  }

  /// Human role used in the tap callout.
  static String roleFor(int index, int count) {
    if (index == 0) return 'Start';
    if (index == count - 1) return 'Destination';
    return 'Stop $index';
  }

  static IconData iconFor(int index, int count) {
    if (index == 0) return Icons.trip_origin_rounded;
    if (index == count - 1) return Icons.flag_rounded;
    return Icons.circle;
  }

  /// flutter_map anchors a marker box *opposite* to [Marker.alignment]:
  /// [Alignment.topCenter] means "the whole box sits above the coordinate",
  /// which is what a pin whose tail tip must touch its stop needs. Using
  /// `bottomCenter` (the intuitive-looking value) hangs the pin a full box
  /// height *below* its stop — the pins then float off the route line.
  static const Alignment pinAnchor = Alignment.topCenter;

  /// Marker box of a station pin. The pin is painted at the bottom of the box
  /// (tail tip on the coordinate), so this height is also the clearance that
  /// anything floating above a pin — the tap callout — has to leave.
  static Size pinBox(bool prominent) =>
      prominent ? const Size(74, 66) : const Size(60, 54);

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color onSurfaceMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withAlpha(170);

  /// Softer in dark mode: heavy shadows on a dark basemap read as smudges.
  static List<BoxShadow> shadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 34 : 18),
        blurRadius: isDark ? 14 : 18,
        offset: Offset(0, isDark ? 4 : 6),
      ),
    ];
  }

  static BorderRadius get pill => BorderRadius.circular(AppTokens.radiusSheet);

  static TextStyle pillLabel(BuildContext context) => AppTextThemes.caption(
    Theme.of(context).colorScheme,
  ).copyWith(fontWeight: FontWeight.w800);
}
