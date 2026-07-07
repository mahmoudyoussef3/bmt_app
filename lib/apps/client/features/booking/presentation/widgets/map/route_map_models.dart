import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';

/// A single mapped stop: its coordinate and (optional) display name.
class RouteMapStop {
  const RouteMapStop({required this.coordinate, this.name = ''});

  final LatLng coordinate;
  final String name;
}

/// Optional trip facts shown in the map's info overlay. Every field is
/// optional; missing values simply don't render. Distance/duration left null
/// are filled from road-geometry results when those are available.
class RouteMapInfoData {
  const RouteMapInfoData({
    this.distance,
    this.duration,
    this.status,
    this.availableSeats,
    this.passengerCount,
  });

  final String? distance;
  final String? duration;
  final String? status;
  final int? availableSeats;
  final int? passengerCount;
}

/// Converts raw pins into ordered, de-duplicated map stops, dropping invalid
/// coordinates so the UI never renders a marker for data that does not exist.
List<RouteMapStop> routeMapStopsFromPins(List<MapPinOption> pins) {
  final points = <RouteMapStop>[];
  final seen = <String>{};

  for (final pin in pins) {
    final lat = pin.x;
    final lng = pin.y;
    final valid =
        lat.isFinite &&
        lng.isFinite &&
        !(lat == 0 && lng == 0) &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
    if (!valid) continue;
    final key = '${lat.toStringAsFixed(6)}:${lng.toStringAsFixed(6)}';
    if (!seen.add(key)) continue;
    points.add(
      RouteMapStop(coordinate: LatLng(lat, lng), name: pin.label.trim()),
    );
  }
  return points;
}

/// Shared visual tokens for the route map so the layer, marker and overlay
/// pieces stay in sync (colors, labels, casing, pills).
class RouteMapStyle {
  const RouteMapStyle._();

  static Color start(BuildContext context) => AppColors.secondary;

  static Color end(BuildContext context) => Theme.of(context).colorScheme.error;

  static Color stop(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color routeLine(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

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
