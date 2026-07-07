import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';

/// The assigned vehicle's icon, type, name, and code.
class TripVehicleCard extends StatelessWidget {
  const TripVehicleCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClientColors.primary.withAlpha(40),
                  ClientColors.primaryMuted.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: ClientColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripInlineBadge(
                  label: trip.vehicleType,
                  color: ClientColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  trip.vehicleName,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vehicle code: ${trip.vehicleId}',
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
