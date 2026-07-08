import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_active_state_content.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_formatters.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_sheet_status_indicator.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// The active-trip bottom sheet body: a status headline plus whichever
/// state-specific view matches [currentState].
class TrackingActiveStateDetails extends StatelessWidget {
  const TrackingActiveStateDetails({
    super.key,
    required this.trip,
    required this.currentState,
    required this.progress,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onCallDriver,
    required this.onChatDriver,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
    required this.onBookAnotherTrip,
    this.scrollController,
  });

  /// The draggable sheet's scroll controller, when this list is the sheet's
  /// sole scrollable (mobile). Null on tablet, where this widget sits inside
  /// its own bounded panel instead of a [DraggableScrollableSheet].
  final ScrollController? scrollController;

  final TrackingTripData? trip;
  final TrackingTripState currentState;
  final RouteProgressSnapshot? progress;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final VoidCallback onCallDriver;
  final VoidCallback onChatDriver;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;
  final VoidCallback onBookAnotherTrip;

  String get _pickupName =>
      trip?.pickupName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.first : 'Pickup');
  String get _destinationName =>
      trip?.destinationName ?? (trip?.stops.isNotEmpty == true ? trip!.stops.last : 'Destination');

  @override
  Widget build(BuildContext context) {
    final stateContent = buildTrackingActiveStateContent(
      currentState: currentState,
      trip: trip,
      progress: progress,
      riderPickupName: trip?.passengerPickupName ?? _pickupName,
      pickupName: _pickupName,
      destinationName: _destinationName,
      driverRating: driverRating,
      vehicleRating: vehicleRating,
      routeRating: routeRating,
      onCallDriver: onCallDriver,
      onChatDriver: onChatDriver,
      onRateDriver: onRateDriver,
      onRateVehicle: onRateVehicle,
      onRateRoute: onRateRoute,
      onBookAnotherTrip: onBookAnotherTrip,
    );

    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Center(
          child: Semantics(
            label: 'Drag to expand trip details',
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        TrackingSheetStatusIndicator(
          currentState: currentState,
          hasLiveVehicleLocation: trip?.hasLiveVehicleLocation == true,
          driverName: trip?.displayDriverName ?? 'Captain',
          pickupName: _pickupName,
          destinationName: _destinationName,
          arrivalTimeLabel: formatTrackingTime(trip?.arrivalAt),
        ),
        const SizedBox(height: 16),
        AnimatedSize(duration: const Duration(milliseconds: 300), child: stateContent),
      ],
    );
  }
}
