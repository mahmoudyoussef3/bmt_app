import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/boarding_view.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/completed_view.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/driver_on_way_view.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/in_progress_view.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_formatters.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

/// Builds the state-specific sheet body for [currentState], used by
/// [TrackingActiveStateDetails].
Widget buildTrackingActiveStateContent({
  required TrackingTripState currentState,
  required TrackingTripData? trip,
  required RouteProgressSnapshot? progress,
  required String riderPickupName,
  required String pickupName,
  required String destinationName,
  required int driverRating,
  required int vehicleRating,
  required int routeRating,
  required VoidCallback onCallDriver,
  required VoidCallback onChatDriver,
  required ValueChanged<int> onRateDriver,
  required ValueChanged<int> onRateVehicle,
  required ValueChanged<int> onRateRoute,
  required VoidCallback onBookAnotherTrip,
}) {
  return switch (currentState) {
    TrackingTripState.driverOnWay => DriverOnWayView(
        progress: progress,
        riderPickupName: riderPickupName,
        riderBoarded: trip?.passengerBoarded ?? false,
        fallbackArrival: trip?.departureAt,
        driverInitials: trip?.driverInitials ?? 'DR',
        driverName: trip?.displayDriverName ?? 'Driver assigned',
        driverRatingLabel: trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
        onCallDriver: onCallDriver,
        onChatDriver: onChatDriver,
        vehicleType: trip?.vehicleType ?? 'Vehicle',
        vehiclePlate: trip?.displayVehiclePlate ?? 'Plate pending',
        vehicleName: trip?.displayVehicleName ?? 'Assigned vehicle',
        liveLocationLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
        vehicleSpeedKmh: trip?.vehicleSpeedKmh,
      ),
    TrackingTripState.boarding => BoardingView(
        progress: progress,
        riderPickupName: riderPickupName,
        riderBoarded: trip?.passengerBoarded ?? false,
        fallbackArrival: trip?.departureAt,
        bookingLabel: trip?.bookingId == null
            ? 'Booking reference pending'
            : 'Booking: ${trip!.bookingId}',
        driverInitials: trip?.driverInitials ?? 'DR',
        driverName: trip?.displayDriverName ?? 'Driver assigned',
        driverRatingLabel: trip?.driverRating?.toStringAsFixed(1) ?? 'N/A',
        onCallDriver: onCallDriver,
        onChatDriver: onChatDriver,
      ),
    TrackingTripState.inProgress => InProgressView(
        progress: progress,
        riderPickupName: riderPickupName,
        riderBoarded: trip?.passengerBoarded ?? false,
        fallbackArrival: trip?.arrivalAt,
        speedLabel: trip?.vehicleSpeedKmh == null ? 'Pending' : '${trip!.vehicleSpeedKmh!.round()} km/h',
        gpsLabel: trip?.hasLiveVehicleLocation == true ? 'Received' : 'Waiting',
        updatedLabel: formatLiveLocationLabel(trip?.vehicleLocationAt),
      ),
    TrackingTripState.completed => CompletedView(
        routeName: trip?.routeName ?? 'Trip route',
        pickupName: pickupName,
        destinationName: destinationName,
        arrivalTimeLabel: formatTrackingTime(trip?.arrivalAt),
        driverRating: driverRating,
        vehicleRating: vehicleRating,
        routeRating: routeRating,
        onRateDriver: onRateDriver,
        onRateVehicle: onRateVehicle,
        onRateRoute: onRateRoute,
        onBookAnotherTrip: onBookAnotherTrip,
      ),
    TrackingTripState.notStarted => const SizedBox.shrink(),
  };
}
