import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_countdown_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_driver_info_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_formatters.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_text_rows.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_quick_actions.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_route_info_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_trip_timeline.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_vehicle_info_card.dart';

/// Pre-trip details list: countdown, quick actions, timeline, and trip
/// facts. Shown before the trip enters any active state.
class TrackingPretripList extends StatelessWidget {
  const TrackingPretripList({
    super.key,
    required this.shellMode,
    required this.trip,
    required this.currentTimelineStep,
    required this.onViewRoute,
    required this.onContactDriver,
    required this.onSupport,
  });

  final bool shellMode;
  final TrackingTripData? trip;
  final int currentTimelineStep;
  final VoidCallback onViewRoute;
  final VoidCallback onContactDriver;
  final VoidCallback onSupport;

  String get _pickupName =>
      trip?.pickupName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.first : 'Pickup');
  String get _destinationName =>
      trip?.destinationName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.last : 'Destination');

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, shellMode ? 16 : 84, 16, 24),
      children: [
        TrackingCountdownCard(
          relativeDeparture: formatRelativeDeparture(trip?.departureAt),
          departureTimeLabel: formatTrackingTime(trip?.departureAt),
          hasLiveVehicleLocation: trip?.hasLiveVehicleLocation == true,
          liveLocationLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
        ),
        const SizedBox(height: 16),
        TrackingQuickActions(
          onViewRoute: onViewRoute,
          onContactDriver: onContactDriver,
          onSupport: onSupport,
        ),
        const SizedBox(height: 20),
        const TrackingSectionTitle(title: 'Trip Status Timeline', icon: Icons.linear_scale),
        TrackingTripTimeline(
          currentStep: currentTimelineStep,
          driverName: trip?.displayDriverName ?? 'Driver',
          hasLiveVehicleLocation: trip?.hasLiveVehicleLocation == true,
        ),
        const SizedBox(height: 20),
        const TrackingSectionTitle(title: 'Trip Details', icon: Icons.info_outline),
        TrackingRouteInfoCard(
          routeName: trip?.routeName ?? 'Trip route',
          pickupName: _pickupName,
          destinationName: _destinationName,
          departureTimeLabel: formatTrackingTime(trip?.departureAt),
          arrivalTimeLabel: formatTrackingTime(trip?.arrivalAt),
        ),
        const SizedBox(height: 16),
        TrackingVehicleInfoCard(
          vehicleType: trip?.vehicleType ?? 'Vehicle',
          vehiclePlate: trip?.displayVehiclePlate ?? 'Plate pending',
          vehicleName: trip?.displayVehicleName ?? 'Assigned vehicle',
          liveLocationLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
          vehicleSpeedKmh: trip?.vehicleSpeedKmh,
        ),
        const SizedBox(height: 16),
        TrackingDriverInfoCard(
          driverInitials: trip?.driverInitials ?? 'DR',
          driverName: trip?.displayDriverName ?? 'Driver assigned',
          driverRatingLabel: trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
          onCallDriver: onContactDriver,
        ),
      ],
    );
  }
}
