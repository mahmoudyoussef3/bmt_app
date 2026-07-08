import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// Basemap attribution required by OpenStreetMap + CARTO usage terms, with
/// OpenRouteService credited when its road geometry is on screen.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, this.showRouting = false});

  final bool showRouting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(210),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        showRouting
            ? '© OpenStreetMap · CARTO · openrouteservice'
            : '© OpenStreetMap · CARTO',
        style: AppTextThemes.badgeText(
          Theme.of(context).colorScheme,
        ).copyWith(fontSize: 9),
      ),
    );
  }
}
