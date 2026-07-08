import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_trip_timeline_step.dart';

/// The overall booking-lifecycle timeline shown before the trip starts
/// (Booking Confirmed → ... → Trip Completed). Distinct from
/// `TrackingStopsTimeline`, which tracks per-stop progress once en route.
class TrackingTripTimeline extends StatelessWidget {
  const TrackingTripTimeline({
    super.key,
    required this.currentStep,
    required this.driverName,
    required this.hasLiveVehicleLocation,
  });

  final int currentStep;
  final String driverName;
  final bool hasLiveVehicleLocation;

  static const _steps = [
    'Booking Confirmed',
    'Driver Assigned',
    'Driver Heading To Pickup',
    'Boarding Started',
    'Trip Started',
    'Trip Completed',
  ];

  String _description(int index) {
    return switch (index) {
      1 => '$driverName is assigned to your trip.',
      2 => hasLiveVehicleLocation
          ? 'Vehicle location is updating from the captain app.'
          : 'Waiting for captain location sharing.',
      3 => 'Vehicle is at pickup or boarding is open.',
      4 => 'Trip is live on the route.',
      5 => 'Trip has arrived.',
      _ => 'Booking is confirmed.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: List.generate(
          _steps.length,
          (index) => TrackingTripTimelineStep(
            label: _steps[index],
            description: _description(index),
            isCompleted: index < currentStep,
            isActive: index == currentStep,
            isRemaining: index > currentStep,
            isLast: index == _steps.length - 1,
          ),
        ),
      ),
    );
  }
}
