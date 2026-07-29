import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';

/// The office's explicit passenger rating: star, average, review count.
/// A new office shows "no ratings yet" rather than a misleading 0.0.
class OfficeRatingRow extends StatelessWidget {
  const OfficeRatingRow({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    if (!office.hasRating) {
      return Text(
        context.l10n.offices_noRatingsYet,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
        const SizedBox(width: 3),
        Text(
          office.rating.toStringAsFixed(1),
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.offices_ratingsCount(office.ratingsCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }
}
