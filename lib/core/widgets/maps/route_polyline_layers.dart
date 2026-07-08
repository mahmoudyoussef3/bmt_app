import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Builds the layered "premium navigation" stroke — soft glow, casing, then a
/// vivid rounded line — with independent per-layer opacity so the route can
/// fade in progressively. The glow is dimmer and the casing darker in dark
/// mode so the line sits into the basemap instead of blooming over it.
///
/// Pass [color] to override the brand route color (used to draw a muted
/// "remaining" segment next to a full-color "traveled" one); set [glow] to
/// `false` for secondary/muted segments so the glow doesn't stack visually
/// on top of the primary segment's.
List<Polyline> buildRoutePolylines(
  BuildContext context,
  List<LatLng> points, {
  double glowOpacity = 1,
  double casingOpacity = 1,
  double lineOpacity = 1,
  Color? color,
  bool glow = true,
}) {
  if (points.length < 2) return const [];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final line = color ?? MapStyle.routeLine(context);
  final glowAlpha = isDark ? 22 : 38;
  final casing = isDark ? const Color(0xFF10151D) : Colors.white;

  Polyline stroke(Color strokeColor, int alpha, double width) => Polyline(
    points: points,
    color: strokeColor.withAlpha(alpha),
    strokeWidth: width,
    strokeJoin: StrokeJoin.round,
    strokeCap: StrokeCap.round,
  );

  return [
    if (glow && glowOpacity > 0)
      stroke(line, (glowAlpha * glowOpacity).round(), 15),
    if (casingOpacity > 0) stroke(casing, (255 * casingOpacity).round(), 11),
    if (lineOpacity > 0) stroke(line, (255 * lineOpacity).round(), 6),
  ];
}

/// The static route path. Used when the line is already fully revealed (or
/// animation is not wanted); the animated variant lives in
/// `animated_route_line.dart`.
class RouteMapPolylineLayer extends StatelessWidget {
  const RouteMapPolylineLayer({super.key, required this.coordinates});

  final List<LatLng> coordinates;

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(polylines: buildRoutePolylines(context, coordinates));
  }
}
