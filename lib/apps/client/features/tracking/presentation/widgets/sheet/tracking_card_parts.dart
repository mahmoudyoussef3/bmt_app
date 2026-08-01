import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Small shapes the sheet's cards share, so a status chip in the booking card
/// and one in the crew card are visibly the same object.
class TrackingChip extends StatelessWidget {
  const TrackingChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// One leg of the rider's journey: an icon, what it is, and where.
class TrackingLegRow extends StatelessWidget {
  const TrackingLegRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? ClientColors.primaryFor(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
              Text(value, style: ClientTypography.bodyMedium(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A real service rating, or an honest "not rated yet". Never a fabricated
/// score, and never a 0.0 for a captain nobody has reviewed.
class TrackingRatingRow extends StatelessWidget {
  const TrackingRatingRow({
    super.key,
    required this.hasRating,
    required this.text,
  });

  final bool hasRating;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (!hasRating) {
      return Text(
        text,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textTertiaryFor(context)),
      );
    }
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: 15,
          color: ClientColors.ratingFor(context),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}
