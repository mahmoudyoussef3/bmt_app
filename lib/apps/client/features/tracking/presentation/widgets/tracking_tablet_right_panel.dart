import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_active_state_details.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_driver_info_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_formatters.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_text_rows.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_trip_timeline.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_vehicle_info_card.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Tablet layout's right column: trip timeline/driver/vehicle facts before
/// the trip starts, or the active-state details sheet once it's active.
class TrackingTabletRightPanel extends StatelessWidget {
  const TrackingTabletRightPanel({
    super.key,
    required this.notStarted,
    required this.trip,
    required this.currentState,
    required this.progress,
    required this.currentTimelineStep,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onContactDriver,
    required this.onSupport,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
    required this.onBookAnotherTrip,
  });

  final bool notStarted;
  final TrackingTripData? trip;
  final TrackingTripState currentState;
  final RouteProgressSnapshot? progress;
  final int currentTimelineStep;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final VoidCallback onContactDriver;
  final VoidCallback onSupport;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;
  final VoidCallback onBookAnotherTrip;

  @override
  Widget build(BuildContext context) {
    if (!notStarted) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 24, 24),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: TrackingActiveStateDetails(
            trip: trip,
            currentState: currentState,
            progress: progress,
            driverRating: driverRating,
            vehicleRating: vehicleRating,
            routeRating: routeRating,
            onCallDriver: onContactDriver,
            onChatDriver: onSupport,
            onRateDriver: onRateDriver,
            onRateVehicle: onRateVehicle,
            onRateRoute: onRateRoute,
            onBookAnotherTrip: onBookAnotherTrip,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TrackingSectionTitle(title: 'Trip Status Timeline', icon: Icons.linear_scale),
          TrackingTripTimeline(
            currentStep: currentTimelineStep,
            driverName: trip?.displayDriverName ?? 'Driver',
            hasLiveVehicleLocation: trip?.hasLiveVehicleLocation == true,
          ),
          const SizedBox(height: 24),
          TrackingDriverInfoCard(
            driverInitials: trip?.driverInitials ?? 'DR',
            driverName: trip?.displayDriverName ?? 'Driver assigned',
            driverRatingLabel: trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
            onCallDriver: onContactDriver,
          ),
          const SizedBox(height: 16),
          TrackingVehicleInfoCard(
            vehicleType: trip?.vehicleType ?? 'Vehicle',
            vehiclePlate: trip?.displayVehiclePlate ?? 'Plate pending',
            vehicleName: trip?.displayVehicleName ?? 'Assigned vehicle',
            liveLocationLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
            vehicleSpeedKmh: trip?.vehicleSpeedKmh,
          ),
        ],
      ),
    );
  }
}
