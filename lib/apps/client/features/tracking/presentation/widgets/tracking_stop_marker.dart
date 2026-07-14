import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

import 'tracking_stop_marker_parts.dart';

/// A stop on the live map, drawn from one family of circular dots that differ
/// only in size, fill and ring — so the rider reads the route in a single
/// sweep: slate dots behind the bus are done, the ringed pulsing dot is where
/// it is headed next, the red flag is where the trip ends.
class TrackingStopMarker extends StatelessWidget {
  const TrackingStopMarker({
    super.key,
    required this.status,
    required this.isDestination,
    this.name,
  });

  final StopVisitStatus status;
  final bool isDestination;

  /// Rendered under the dot. Only passed for the stops worth naming (the next
  /// one and the destination) — labelling all of them turns the map into a
  /// wall of text at city zoom.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name;
    if (label == null) return _dot(context);
    // The dot stays centered — flutter_map anchors the marker box's center on
    // the coordinate, so a Column would push the dot off its own stop. The
    // label hangs off the bottom of the box instead.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _dot(context),
        Align(
          alignment: Alignment.bottomCenter,
          child: TrackingStopLabel(
            text: label,
            color: isDestination
                ? ClientColors.journeyRed
                : MapStyle.routeLine(context),
          ),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context) {
    final route = MapStyle.routeLine(context);
    if (isDestination && status != StopVisitStatus.departed) {
      return const TrackingStopDot(
        diameter: 24,
        fill: ClientColors.journeyRed,
        icon: Icons.flag_rounded,
      );
    }
    return switch (status) {
      // Done: a flat slate dot that recedes into the traveled trail.
      StopVisitStatus.departed => const TrackingStopDot(
        diameter: 12,
        fill: ClientColors.journeySlate,
      ),
      // The bus is standing at this stop right now.
      StopVisitStatus.arrived => TrackingStopPulse(
        color: route,
        diameter: 24,
        child: TrackingStopDot(
          diameter: 24,
          fill: route,
          icon: Icons.directions_bus_rounded,
        ),
      ),
      // Heading here next: hollow, ringed, breathing.
      StopVisitStatus.next => TrackingStopPulse(
        color: route,
        diameter: 18,
        child: TrackingStopDot(
          diameter: 18,
          fill: Colors.white,
          ring: route,
          ringWidth: 4,
        ),
      ),
      StopVisitStatus.upcoming => TrackingStopDot(
        diameter: 11,
        fill: Colors.white,
        ring: route.withAlpha(150),
        ringWidth: 3,
      ),
    };
  }
}
