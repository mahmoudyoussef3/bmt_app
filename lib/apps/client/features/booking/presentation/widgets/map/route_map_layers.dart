import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';

/// A clean, theme-aware raster basemap.
///
/// Uses CARTO's low-noise basemaps (Voyager in light, Dark Matter in dark) so
/// the route line and stops stay the visual focus instead of competing with a
/// busy default street map. Retina tiles are requested on high-density screens.
class RouteMapTileLayer extends StatelessWidget {
  const RouteMapTileLayer({super.key});

  static const _lightUrl =
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _darkUrl =
      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: isDark ? _darkUrl : _lightUrl,
      retinaMode: RetinaMode.isHighDensity(context),
      userAgentPackageName: 'com.bmt.app',
    );
  }
}

/// Builds the layered "premium navigation" stroke — soft glow, casing, then a
/// vivid rounded line — with independent per-layer opacity so the route can
/// fade in progressively. The glow is dimmer and the casing darker in dark
/// mode so the line sits into the basemap instead of blooming over it.
List<Polyline> buildRoutePolylines(
  BuildContext context,
  List<LatLng> points, {
  double glowOpacity = 1,
  double casingOpacity = 1,
  double lineOpacity = 1,
}) {
  if (points.length < 2) return const [];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final line = RouteMapStyle.routeLine(context);
  final glowAlpha = isDark ? 22 : 38;
  final casing = isDark ? const Color(0xFF10151D) : Colors.white;

  Polyline stroke(Color color, int alpha, double width) => Polyline(
    points: points,
    color: color.withAlpha(alpha),
    strokeWidth: width,
    strokeJoin: StrokeJoin.round,
    strokeCap: StrokeCap.round,
  );

  return [
    if (glowOpacity > 0) stroke(line, (glowAlpha * glowOpacity).round(), 15),
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
