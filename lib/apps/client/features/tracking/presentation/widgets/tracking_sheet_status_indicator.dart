import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_misc_widgets.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Headline strip at the top of the active-trip sheet: a pulsing status dot,
/// a title, and a state-specific subtitle.
class TrackingSheetStatusIndicator extends StatelessWidget {
  const TrackingSheetStatusIndicator({
    super.key,
    required this.currentState,
    required this.hasLiveVehicleLocation,
    required this.driverName,
    required this.pickupName,
    required this.destinationName,
    required this.arrivalTimeLabel,
  });

  final TrackingTripState currentState;
  final bool hasLiveVehicleLocation;
  final String driverName;
  final String pickupName;
  final String destinationName;
  final String arrivalTimeLabel;

  @override
  Widget build(BuildContext context) {
    String title = '';
    String subtitle = '';
    Color toneColor = ClientColors.primary;

    switch (currentState) {
      case TrackingTripState.driverOnWay:
        title = 'Driver On The Way';
        subtitle = hasLiveVehicleLocation
            ? '$driverName is heading towards $pickupName'
            : 'Waiting for the captain to send a location';
        toneColor = ClientColors.journeyGreen;
      case TrackingTripState.boarding:
        title = 'Boarding Started';
        subtitle = 'Vehicle is at $pickupName. Board when instructed.';
        toneColor = ClientColors.primary;
      case TrackingTripState.inProgress:
        title = 'Trip In Progress';
        subtitle = 'Heading to $destinationName';
        toneColor = ClientColors.primary;
      case TrackingTripState.completed:
        title = 'Arrived Safely';
        subtitle = 'Trip completed at $arrivalTimeLabel';
        toneColor = ClientColors.journeyGreen;
      case TrackingTripState.notStarted:
        break;
    }

    return Row(
      children: [
        TrackingPulseIndicator(color: toneColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
