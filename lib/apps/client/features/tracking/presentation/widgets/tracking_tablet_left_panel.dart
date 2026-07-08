import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_countdown_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_formatters.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_quick_actions.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_route_info_card.dart';

/// Tablet layout's left column: countdown/route facts before the trip
/// starts, or the full-bleed map once it's active.
class TrackingTabletLeftPanel extends StatelessWidget {
  const TrackingTabletLeftPanel({
    super.key,
    required this.notStarted,
    required this.trip,
    required this.map,
    required this.onViewRoute,
    required this.onContactDriver,
    required this.onSupport,
  });

  final bool notStarted;
  final TrackingTripData? trip;
  final Widget map;
  final VoidCallback onViewRoute;
  final VoidCallback onContactDriver;
  final VoidCallback onSupport;

  String get _pickupName =>
      trip?.pickupName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.first : 'Pickup');
  String get _destinationName =>
      trip?.destinationName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.last : 'Destination');

  @override
  Widget build(BuildContext context) {
    if (!notStarted) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: map),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrackingCountdownCard(
            relativeDeparture: formatRelativeDeparture(trip?.departureAt),
            departureTimeLabel: formatTrackingTime(trip?.departureAt),
            hasLiveVehicleLocation: trip?.hasLiveVehicleLocation == true,
            liveLocationLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
          ),
          const SizedBox(height: 20),
          TrackingRouteInfoCard(
            routeName: trip?.routeName ?? 'Trip route',
            pickupName: _pickupName,
            destinationName: _destinationName,
            departureTimeLabel: formatTrackingTime(trip?.departureAt),
            arrivalTimeLabel: formatTrackingTime(trip?.arrivalAt),
          ),
          const SizedBox(height: 20),
          TrackingQuickActions(
            onViewRoute: onViewRoute,
            onContactDriver: onContactDriver,
            onSupport: onSupport,
          ),
        ],
      ),
    );
  }
}
