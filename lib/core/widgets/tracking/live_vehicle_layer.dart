import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'animated_vehicle_marker.dart';
import 'vehicle_track_controller.dart';

/// FlutterMap layer that renders the live vehicle: GPS accuracy circle,
/// heading-rotated marker, and optional plate label.
///
/// Place inside `FlutterMap.children` after the tile/polyline layers. Only
/// this subtree rebuilds on animation frames — tiles and route lines are
/// untouched, which keeps per-frame work minimal.
class LiveVehicleLayer extends StatelessWidget {
  const LiveVehicleLayer({
    super.key,
    required this.controller,
    required this.color,
    this.label,
    this.pulseValue,
    this.markerSize = 48,
    this.minAccuracyToShowMeters = 15,
  });

  final VehicleTrackController controller;
  final Color color;

  /// Optional caption under the marker (e.g. plate number on the dashboard).
  final String? label;

  /// 0..1 external pulse phase for the marker halo.
  final double? pulseValue;
  final double markerSize;

  /// Accuracy circles smaller than this are noise at bus-map zoom levels
  /// and are hidden instead of flickering under the marker.
  final double minAccuracyToShowMeters;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final sample = controller.sample;
        if (sample == null) return const SizedBox.shrink();

        final point = LatLng(sample.latitude, sample.longitude);
        final accuracy = sample.accuracyMeters;
        final labelHeight = label == null ? 0.0 : 18.0;

        return Stack(
          children: [
            if (accuracy != null && accuracy >= minAccuracyToShowMeters)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: point,
                    radius: accuracy,
                    useRadiusInMeter: true,
                    color: color.withAlpha(22),
                    borderColor: color.withAlpha(70),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: markerSize + 26,
                  height: markerSize + labelHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedVehicleMarker(
                        sample: sample,
                        color: color,
                        pulseValue: pulseValue,
                        size: markerSize,
                      ),
                      if (label != null)
                        _PlateLabel(text: label!, isStale: sample.isStale),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PlateLabel extends StatelessWidget {
  const _PlateLabel({required this.text, required this.isStale});

  final String text;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isStale ? scheme.error : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
