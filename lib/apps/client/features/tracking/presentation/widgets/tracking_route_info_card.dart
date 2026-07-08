import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_route_timeline_row.dart';

/// Pickup → destination summary with scheduled times, shown before the trip
/// starts.
class TrackingRouteInfoCard extends StatelessWidget {
  const TrackingRouteInfoCard({
    super.key,
    required this.routeName,
    required this.pickupName,
    required this.destinationName,
    required this.departureTimeLabel,
    required this.arrivalTimeLabel,
  });

  final String routeName;
  final String pickupName;
  final String destinationName;
  final String departureTimeLabel;
  final String arrivalTimeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus_rounded, color: ClientColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  routeName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          TrackingRouteTimelineRow(
            icon: Icons.trip_origin_rounded,
            color: ClientColors.journeyGreen,
            type: 'Pickup Location',
            location: pickupName,
            timeInfo: 'Scheduled departure: $departureTimeLabel',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(width: 2, height: 24, color: ClientColors.borderFor(context)),
          ),
          TrackingRouteTimelineRow(
            icon: Icons.location_on_rounded,
            color: scheme.tertiary,
            type: 'Destination',
            location: destinationName,
            timeInfo: 'Expected arrival: $arrivalTimeLabel',
          ),
        ],
      ),
    );
  }
}
