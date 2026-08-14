import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// The assigned vehicle: its name and class on the left, its fleet code on the
/// right — one line of identity, the way a plate is read off a bus.
class TripVehicleCard extends StatelessWidget {
  const TripVehicleCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final code = trip.vehicleId.trim();

    return Row(
      children: [
        TripSoftIcon(
          icon: Icons.directions_bus_filled_rounded,
          color: ClientColors.primaryFor(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicleNameFor(context, trip),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 6),
              // The class and the fleet code sit under the name rather than
              // beside it: on a narrow phone a fixed-width code chip on the
              // same line ate the name it was labelling.
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (trip.vehicleType.trim().isNotEmpty)
                    TripInlineBadge(
                      label: trip.vehicleType,
                      color: ClientColors.primaryFor(context),
                    ),
                  if (code.isNotEmpty) _FleetCodeChip(code: code),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The vehicle's fleet code, set like a plate: tabular figures and wide
/// tracking, because it is read character by character.
class _FleetCodeChip extends StatelessWidget {
  const _FleetCodeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 13,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(width: 6),
          Text(
            code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.textPrimaryFor(context),
              letterSpacing: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
