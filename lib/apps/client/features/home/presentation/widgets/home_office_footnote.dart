import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The tile's closing line: where the operator drives when it has published
/// service areas, and how many riders scored it when it has not — always
/// finished with a trailing chevron so every tile reads as tappable.
class HomeOfficeFootnote extends StatelessWidget {
  const HomeOfficeFootnote({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final style = ClientTypography.labelSmall(
      context,
    ).copyWith(color: ClientColors.textSecondaryFor(context));

    final label = office.serviceAreas.isEmpty
        ? Text(
            office.hasRating
                ? context.l10n.offices_ratingsCount(office.ratingsCount)
                : context.l10n.offices_noRatingsYet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          )
        : Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 13,
                color: ClientColors.textTertiaryFor(context),
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

    return Row(
      children: [
        Expanded(child: label),
        const SizedBox(width: 4),
        DirectionalIcon(
          Icons.arrow_forward_rounded,
          size: 13,
          color: ClientColors.primaryFor(context),
        ),
      ],
    );
  }
}
