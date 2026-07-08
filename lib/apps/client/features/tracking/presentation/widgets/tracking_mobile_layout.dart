import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_active_sheet.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_pretrip_list.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Phone-width layout: a pre-trip details list, or a full-bleed map with a
/// draggable sheet once the trip is active.
class TrackingMobileLayout extends StatelessWidget {
  const TrackingMobileLayout({
    super.key,
    required this.shellMode,
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
    required this.sheetController,
  });

  final bool shellMode;
  final TrackingTripState currentState;
  final TrackingTripData? trip;
  final RouteProgressSnapshot? progress;
  final int currentTimelineStep;
  final Widget map;
  final DraggableScrollableController sheetController;
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
    if (currentState == TrackingTripState.notStarted) {
      return TrackingPretripList(
        shellMode: shellMode,
        trip: trip,
        currentTimelineStep: currentTimelineStep,
        onViewRoute: onViewRoute,
        onContactDriver: onContactDriver,
        onSupport: onSupport,
      );
    }

    return TrackingActiveSheet(
      map: map,
      sheetController: sheetController,
      trip: trip,
      currentState: currentState,
      progress: progress,
      driverRating: driverRating,
      vehicleRating: vehicleRating,
      routeRating: routeRating,
      onContactDriver: onContactDriver,
      onChatDriver: onSupport,
      onRateDriver: onRateDriver,
      onRateVehicle: onRateVehicle,
      onRateRoute: onRateRoute,
      onBookAnotherTrip: onBookAnotherTrip,
    );
  }
}
