import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_active_state_details.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Full-bleed map with a draggable bottom sheet of state-specific details —
/// the layout for every active trip state (driver on the way, boarding, in
/// progress, completed).
class TrackingActiveSheet extends StatelessWidget {
  const TrackingActiveSheet({
    super.key,
    required this.map,
    required this.sheetController,
    required this.trip,
    required this.currentState,
    required this.progress,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onContactDriver,
    required this.onChatDriver,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
    required this.onBookAnotherTrip,
  });

  final Widget map;
  final DraggableScrollableController sheetController;
  final TrackingTripData? trip;
  final TrackingTripState currentState;
  final RouteProgressSnapshot? progress;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final VoidCallback onContactDriver;
  final VoidCallback onChatDriver;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;
  final VoidCallback onBookAnotherTrip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: map),
        DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: 0.4,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 24, offset: const Offset(0, -4)),
                ],
              ),
              child: TrackingActiveStateDetails(
                scrollController: scrollController,
                trip: trip,
                currentState: currentState,
                progress: progress,
                driverRating: driverRating,
                vehicleRating: vehicleRating,
                routeRating: routeRating,
                onCallDriver: onContactDriver,
                onChatDriver: onChatDriver,
                onRateDriver: onRateDriver,
                onRateVehicle: onRateVehicle,
                onRateRoute: onRateRoute,
                onBookAnotherTrip: onBookAnotherTrip,
              ),
            );
          },
        ),
      ],
    );
  }
}
