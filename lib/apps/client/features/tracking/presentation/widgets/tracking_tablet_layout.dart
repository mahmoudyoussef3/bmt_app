import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_tablet_left_panel.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_tablet_right_panel.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Wide-viewport layout: map/countdown on the left, timeline/details/sheet
/// on the right, side by side instead of stacked.
class TrackingTabletLayout extends StatelessWidget {
  const TrackingTabletLayout({
    super.key,
    required this.currentState,
    required this.trip,
    required this.progress,
    required this.currentTimelineStep,
    required this.map,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onViewRoute,
    required this.onContactDriver,
    required this.onSupport,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
    required this.onBookAnotherTrip,
  });

  final TrackingTripState currentState;
  final TrackingTripData? trip;
  final RouteProgressSnapshot? progress;
  final int currentTimelineStep;
  final Widget map;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final VoidCallback onViewRoute;
  final VoidCallback onContactDriver;
  final VoidCallback onSupport;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;
  final VoidCallback onBookAnotherTrip;

  @override
  Widget build(BuildContext context) {
    final notStarted = currentState == TrackingTripState.notStarted;
    return Padding(
      padding: const EdgeInsets.only(top: 84.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: TrackingTabletLeftPanel(
              notStarted: notStarted,
              trip: trip,
              map: map,
              onViewRoute: onViewRoute,
              onContactDriver: onContactDriver,
              onSupport: onSupport,
            ),
          ),
          Expanded(
            flex: 4,
            child: TrackingTabletRightPanel(
              notStarted: notStarted,
              trip: trip,
              currentState: currentState,
              progress: progress,
              currentTimelineStep: currentTimelineStep,
              driverRating: driverRating,
              vehicleRating: vehicleRating,
              routeRating: routeRating,
              onContactDriver: onContactDriver,
              onSupport: onSupport,
              onRateDriver: onRateDriver,
              onRateVehicle: onRateVehicle,
              onRateRoute: onRateRoute,
              onBookAnotherTrip: onBookAnotherTrip,
            ),
          ),
        ],
      ),
    );
  }
}
