import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/completed_rating_card.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/state_details/completed_trip_summary_card.dart';

/// Sheet content once the trip has arrived: summary, ratings, and a CTA to
/// book again.
class CompletedView extends StatelessWidget {
  const CompletedView({
    super.key,
    required this.routeName,
    required this.pickupName,
    required this.destinationName,
    required this.arrivalTimeLabel,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
    required this.onBookAnotherTrip,
  });

  final String routeName;
  final String pickupName;
  final String destinationName;
  final String arrivalTimeLabel;
  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;
  final VoidCallback onBookAnotherTrip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompletedTripSummaryCard(
          routeName: routeName,
          pickupName: pickupName,
          destinationName: destinationName,
          arrivalTimeLabel: arrivalTimeLabel,
        ),
        const SizedBox(height: 16),
        CompletedRatingCard(
          driverRating: driverRating,
          vehicleRating: vehicleRating,
          routeRating: routeRating,
          onRateDriver: onRateDriver,
          onRateVehicle: onRateVehicle,
          onRateRoute: onRateRoute,
        ),
        const SizedBox(height: 20),
        ClientButton(label: 'Book Another Trip', expand: true, onPressed: onBookAnotherTrip),
      ],
    );
  }
}
