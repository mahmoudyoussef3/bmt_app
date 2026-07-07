import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_premium_panel.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// A prompt to rate the trip, shown once a trip is completed.
class TripCompletedCard extends StatelessWidget {
  const TripCompletedCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return TripPremiumPanel(
      child: Row(
        children: [
          const TripSoftIcon(
            icon: Icons.star_rounded,
            color: ClientColors.journeyAmber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Help us improve by rating your trip with ${trip.driverName}.',
              style: ClientTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
