import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Where a stop sits in the journey. Drives the rail marker and the accent
/// color; nothing else in the timeline is colored.
enum TimelineStopKind { origin, waypoint, destination }

/// The rail column of a timeline row: the stop's marker plus the connector
/// running down to the next stop.
///
/// Only the two endpoints are filled with an accent (cyan = board here,
/// blue = journey ends here). Intermediate stops are neutral numbered rings so
/// a long route reads as one calm line rather than a strip of colored cards.
class TimelineStopDot extends StatelessWidget {
  const TimelineStopDot({
    super.key,
    required this.kind,
    required this.order,
    required this.isLast,
  });

  final TimelineStopKind kind;
  final int order;
  final bool isLast;

  /// Every one of these resolves through the palette rather than naming a
  /// literal. The origin used to take the bare `ClientColors.journeyCyan`
  /// constant, which is the *light* palette's brand blue whatever the theme —
  /// so in dark mode the "start" chip drew navy text on a navy tint and became
  /// unreadable. The light-mode result is unchanged: `journeyCyan` and the
  /// palette primary are the same blue there.
  static Color accentFor(BuildContext context, TimelineStopKind kind) {
    return switch (kind) {
      TimelineStopKind.origin => ClientColors.journeyCyanFor(context),
      TimelineStopKind.destination => ClientColors.primaryFor(context),
      TimelineStopKind.waypoint => ClientColors.textTertiaryFor(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWaypoint = kind == TimelineStopKind.waypoint;

    return Column(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: isWaypoint
              ? _WaypointRing(order: order)
              : _EndpointMarker(color: accentFor(context, kind), kind: kind),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: scheme.outline.withAlpha(60),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _EndpointMarker extends StatelessWidget {
  const _EndpointMarker({required this.color, required this.kind});

  final Color color;
  final TimelineStopKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(38), width: 3),
      ),
      child: Icon(
        kind == TimelineStopKind.origin
            ? Icons.my_location_rounded
            : Icons.flag_rounded,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}

class _WaypointRing extends StatelessWidget {
  const _WaypointRing({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline.withAlpha(90), width: 1.5),
      ),
      child: Text(
        '$order',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ClientColors.textTertiaryFor(context),
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
