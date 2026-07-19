import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Header card summarising how many trips/vehicles are available.
class VehicleListingHeader extends StatelessWidget {
  const VehicleListingHeader({super.key, required this.vehiclesCount});

  final int vehiclesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ClientColors.primaryContainerFor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: ClientColors.primaryFor(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.booking_availableTripsLabel,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.booking_tripOptionsWithVehicles(vehiclesCount),
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
