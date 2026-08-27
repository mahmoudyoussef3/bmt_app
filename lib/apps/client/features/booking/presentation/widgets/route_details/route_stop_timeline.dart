import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_inline_empty.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_timeline_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_tile.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route Details' ordered stop timeline: every station the line serves, in
/// order, when the bus is expected at each and what a passenger may do there —
/// with a graceful empty state when the operator has not published stations
/// yet.
///
/// This is the screen's main content now that fares, departures-to-pick,
/// packages and the operator have moved into the booking steps that actually
/// decide them. Stations are the one thing a rider needs *before* committing
/// to a line, so they get the room.
///
/// The card carries no "edit stops" action. The line is fixed: a rider reading
/// it has already searched a corridor, and the pickup and drop-off they will
/// actually travel between are chosen on the wizard's first step, against this
/// very list. An edit button here changed the *search*, which is a different
/// thing wearing the same word.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({
    super.key,
    required this.points,
    required this.referenceDeparture,
  });

  final List<RoutePointData> points;

  /// The raw `HH:mm[:ss]` departure the station clocks are computed from —
  /// the soonest trip on this line. Empty when no departure is published, in
  /// which case stations fall back to "35m after departure".
  final String referenceDeparture;

  @override
  Widget build(BuildContext context) {
    final orderedPoints = [...points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ClientCard(
      padding: ClientSpacing.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteTimelineHeader(stopCount: orderedPoints.length),
          const SizedBox(height: 16),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 18),
          if (orderedPoints.isEmpty)
            RouteDetailsInlineEmpty(
              icon: Icons.alt_route_rounded,
              title: context.l10n.booking_stopsNotPublishedYet,
              subtitle: context.l10n.booking_routeStationsWillAppear,
            )
          else ...[
            ...orderedPoints.asMap().entries.map(
              (entry) => TimelineStopTile(
                point: entry.value,
                isFirst: entry.key == 0,
                isLast: entry.key == orderedPoints.length - 1,
                referenceDeparture: referenceDeparture,
              ),
            ),
            if (_anyStopIsTimed(orderedPoints)) ...[
              const SizedBox(height: 14),
              _EstimateNote(referenceDeparture: referenceDeparture),
            ],
          ],
        ],
      ),
    );
  }

  /// Whether the operator timed any station at all. Without one, every row is
  /// clockless and a note explaining the clocks would explain nothing.
  bool _anyStopIsTimed(List<RoutePointData> points) => points.any(
    (point) =>
        point.arrivalOffset.trim().isNotEmpty ||
        point.departureOffset.trim().isNotEmpty,
  );
}

/// Says out loud what the station clocks are: an estimate, computed from one
/// departure. Traffic decides the rest, and a rider who plans a connection off
/// these numbers deserves to know that before they do.
class _EstimateNote extends StatelessWidget {
  const _EstimateNote({required this.referenceDeparture});

  final String referenceDeparture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final departure = formatTripTime(context, referenceDeparture);
    final color = ClientColors.textTertiaryFor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            departure.isEmpty
                ? l10n.booking_estimatedTimesNote
                : l10n.booking_estimatedTimesFromDeparture(departure),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color, height: 1.45),
          ),
        ),
      ],
    );
  }
}
