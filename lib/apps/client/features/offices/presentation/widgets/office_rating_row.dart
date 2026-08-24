import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';

/// The office's explicit passenger rating: star, average, review count.
/// A new office shows "no ratings yet" rather than a misleading 0.0.
///
/// On a card this sits at the far end of the info row, opposite the service
/// areas, so it is written as tightly as it can be read — the count drops to
/// bare parentheses ([compact]) where the word "reviews" would only crowd out
/// the places the office actually drives to.
class OfficeRatingRow extends StatelessWidget {
  const OfficeRatingRow({
    super.key,
    required this.office,
    this.compact = false,
  });

  final OfficeSummary office;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);

    if (!office.hasRating) {
      return Text(
        context.l10n.offices_noRatingsYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelSmall(context).copyWith(color: muted),
      );
    }

    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 16,
          color: ClientColors.ratingFor(context),
        ),
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
            compact
                ? l10n.offices_ratingsCountCompact(office.ratingsCount)
                : l10n.offices_ratingsCount(office.ratingsCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
