import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';

/// The captain behind this trip and what past passengers thought of them.
///
/// Shows the public averages only — never an individual review. An unrated
/// captain reads as "New captain", not as zero stars.
class VehicleRatingRow extends StatelessWidget {
  const VehicleRatingRow({super.key, required this.vehicle});

  final VehicleDetailData vehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: ClientColors.primaryContainerFor(context),
          child: Text(
            vehicle.driverInitials,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.primaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            vehicle.driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        if (vehicle.hasDriverRating)
          _RatingChip(
            rating: vehicle.driverRating,
            count: vehicle.driverRatingCount,
          )
        else
          Text(
            'New captain',
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ClientColors.journeyAmberLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: ClientColors.journeyAmber,
          ),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($count)',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.onJourneyAmber,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
