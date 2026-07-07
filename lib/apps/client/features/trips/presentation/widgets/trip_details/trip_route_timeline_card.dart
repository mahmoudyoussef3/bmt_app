import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/route_timeline_point.dart';

/// Trip Details' pickup → destination summary.
class TripRouteTimelineCard extends StatelessWidget {
  const TripRouteTimelineCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RouteTimelinePoint(
            icon: Icons.trip_origin_rounded,
            color: ClientColors.journeyGreen,
            title: 'Pickup Point',
            value: trip.pickup,
            time: trip.timeLabel,
          ),
          TimelineConnector(color: ClientColors.borderFor(context)),
          RouteTimelinePoint(
            icon: Icons.location_on_rounded,
            color: ClientColors.journeyRed,
            title: 'Destination',
            value: trip.destination,
            time: 'Arrival follows the route schedule',
          ),
        ],
    );
  }
}
