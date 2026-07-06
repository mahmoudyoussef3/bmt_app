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

/// The route path drawn as a layered stroke: a soft glow underneath, a light
/// casing, then a vivid rounded line on top — the "premium navigation" look.
class RouteMapPolylineLayer extends StatelessWidget {
  const RouteMapPolylineLayer({super.key, required this.coordinates});

  final List<LatLng> coordinates;

  @override
  Widget build(BuildContext context) {
    final line = RouteMapStyle.routeLine(context);
    return PolylineLayer(
      polylines: [
        Polyline(
          points: coordinates,
          color: line.withAlpha(38),
          strokeWidth: 15,
          strokeJoin: StrokeJoin.round,
          strokeCap: StrokeCap.round,
        ),
        Polyline(
          points: coordinates,
          color: line,
          strokeWidth: 6,
          borderColor: Colors.white,
          borderStrokeWidth: 3,
          strokeJoin: StrokeJoin.round,
          strokeCap: StrokeCap.round,
        ),
      ],
    );
  }
}
