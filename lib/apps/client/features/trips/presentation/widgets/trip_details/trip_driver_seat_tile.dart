import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The non-bookable driver seat placeholder shown at the front of the cabin,
/// styled to match the booking flow's own driver seat tile.
class TripDriverSeatTile extends StatelessWidget {
  const TripDriverSeatTile({super.key, required this.size, required this.label});

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_recline_extra_rounded,
            size: size * 0.36,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
