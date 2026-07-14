import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../../domain/entities/tracking_crew.dart';

/// The vehicle line under the captain: what the bus is, and its plate.
///
/// It renders nothing at all when the fleet record has neither — the rider is
/// better served by a shorter card than by "Assigned vehicle / Plate pending".
class TrackingVehicleRow extends StatelessWidget {
  const TrackingVehicleRow({super.key, required this.vehicle});

  final TrackingVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final name = vehicle.displayName;
    final plate = vehicle.displayPlate;
    if (name == null && plate == null) return const SizedBox.shrink();

    final description = [name, vehicle.type].where((p) => p != null).join(' · ');

    return Column(
      children: [
        const SizedBox(height: 12),
        DashedDivider(color: ClientColors.borderFor(context)),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 18,
              color: ClientColors.textSecondaryFor(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(context),
              ),
            ),
            if (plate != null)
              Text(
                plate,
                style: ClientTypography.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
