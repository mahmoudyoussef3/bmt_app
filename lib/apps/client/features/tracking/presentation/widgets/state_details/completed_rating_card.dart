import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_interactive_rating_row.dart';

/// Post-trip star ratings for the captain, vehicle and route.
class CompletedRatingCard extends StatelessWidget {
  const CompletedRatingCard({
    super.key,
    required this.driverRating,
    required this.vehicleRating,
    required this.routeRating,
    required this.onRateDriver,
    required this.onRateVehicle,
    required this.onRateRoute,
  });

  final int driverRating;
  final int vehicleRating;
  final int routeRating;
  final ValueChanged<int> onRateDriver;
  final ValueChanged<int> onRateVehicle;
  final ValueChanged<int> onRateRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate Your Ride Experience', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TrackingInteractiveRatingRow(
            label: 'Rate Captain',
            currentRating: driverRating,
            onRatingChanged: onRateDriver,
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          TrackingInteractiveRatingRow(
            label: 'Rate Shuttle Vehicle',
            currentRating: vehicleRating,
            onRatingChanged: onRateVehicle,
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          TrackingInteractiveRatingRow(
            label: 'Rate Route & Smoothness',
            currentRating: routeRating,
            onRatingChanged: onRateRoute,
            scheme: scheme,
          ),
        ],
      ),
    );
  }
}
