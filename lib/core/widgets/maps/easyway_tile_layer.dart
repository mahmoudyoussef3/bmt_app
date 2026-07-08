import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// The EasyWay basemap.
///
/// Raster tiles alone can't deliver a bespoke vector-map style, so this
/// leans on CARTO's low-noise Voyager (light) / Dark Matter (dark) basemaps —
/// muted roads, subtle water/parks — and lays a faint brand-colored veil over
/// them so the map reads as "EasyWay" rather than generic CARTO, without
/// hurting legibility. Retina tiles are requested on high-density screens.
class EasyWayTileLayer extends StatelessWidget {
  const EasyWayTileLayer({super.key});

  static const _lightUrl =
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _darkUrl =
      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Stack(
      children: [
        TileLayer(
          urlTemplate: isDark ? _darkUrl : _lightUrl,
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.bmt.app',
        ),
        // Brand veil: cool enough to stay invisible as a "filter" but warm
        // the basemap toward EasyWay blue instead of stock CARTO grey.
        IgnorePointer(
          child: ColoredBox(
            color: scheme.primary.withAlpha(isDark ? 16 : 8),
          ),
        ),
      ],
    );
  }
}
