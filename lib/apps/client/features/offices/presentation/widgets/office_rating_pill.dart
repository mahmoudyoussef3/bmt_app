import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';

/// The score as a marketplace badge: the average in a filled amber block with
/// the sample size beneath it.
///
/// Riders read a rating as one thing — "4.7 out of 1,284 people" — so the two
/// numbers are stacked into a single object rather than strung along a line
/// where the count competes with the office name for the same row.
class OfficeRatingPill extends StatelessWidget {
  const OfficeRatingPill({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!office.hasRating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ClientColors.primaryFor(context).withAlpha(22),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
        ),
        child: Text(
          l10n.offices_new,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.primaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ClientColors.journeyAmber.withAlpha(28),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: ClientColors.ratingFor(context),
              ),
              const SizedBox(width: 3),
              Text(
                office.rating.toStringAsFixed(1),
                style: ClientTypography.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.onJourneyAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l10n.offices_ratingsCount(office.ratingsCount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      ],
    );
  }
}
