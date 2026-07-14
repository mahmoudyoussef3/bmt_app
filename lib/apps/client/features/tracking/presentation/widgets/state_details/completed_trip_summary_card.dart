import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_text_rows.dart';

/// Arrival banner plus a compact route/pickup/destination/arrival summary,
/// shown once the trip has completed.
class CompletedTripSummaryCard extends StatelessWidget {
  const CompletedTripSummaryCard({
    super.key,
    required this.routeName,
    required this.pickupName,
    required this.destinationName,
    required this.arrivalTimeLabel,
  });

  final String routeName;
  final String pickupName;
  final String destinationName;
  final String arrivalTimeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.journeyCyan.withAlpha(20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClientColors.journeyCyan.withAlpha(70)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: ClientColors.journeyCyan,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Have Arrived!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.journeyCyan,
                      ),
                    ),
                    Text(
                      'Thank you for riding with Mega Transportation.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20),
              TrackingSummaryRow(label: 'Route', value: routeName),
              TrackingSummaryRow(label: 'Pickup', value: pickupName),
              TrackingSummaryRow(label: 'Destination', value: destinationName),
              TrackingSummaryRow(
                label: 'Arrival Time',
                value: arrivalTimeLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
