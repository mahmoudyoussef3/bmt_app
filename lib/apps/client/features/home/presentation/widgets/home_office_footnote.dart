import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The identity block's closing line: where the operator drives when it has
/// published service areas, and how many riders scored it when it has not.
///
/// It no longer carries a chevron of its own — the card's footer strip is the
/// affordance now, and two arrows on one tile pointed at nothing in particular.
class HomeOfficeFootnote extends StatelessWidget {
  const HomeOfficeFootnote({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final style = ClientTypography.labelSmall(
      context,
    ).copyWith(color: ClientColors.textSecondaryFor(context));

    if (office.serviceAreas.isEmpty) {
      return Text(
        office.hasRating
            ? context.l10n.offices_ratingsCount(office.ratingsCount)
            : context.l10n.offices_noRatingsYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Row(
      children: [
        Icon(
          Icons.place_rounded,
          size: 13,
          color: ClientColors.primaryFor(context),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            office.serviceAreas.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
