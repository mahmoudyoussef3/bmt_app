import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The operator's score, as a pill that sits on the tinted brand band.
///
/// It carries its own opaque surface and border because the band behind it is
/// a gradient: a bare tinted chip lost its edge against the darker end of the
/// sweep. An unrated newcomer wears a neutral "New" pill instead of a
/// misleading 0.0.
class HomeOfficeRatingBadge extends StatelessWidget {
  const HomeOfficeRatingBadge({super.key, required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    final rated = office.hasRating;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: rated ? 8 : 9, vertical: 4),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.sm(context),
      ),
      child: rated ? _score(context) : _newLabel(context),
    );
  }

  Widget _score(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 13,
          color: ClientColors.ratingFor(context),
        ),
        const SizedBox(width: 3),
        Text(
          office.rating.toStringAsFixed(1),
          style: ClientTypography.labelSmall(context).copyWith(
            fontWeight: FontWeight.w900,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }

  Widget _newLabel(BuildContext context) {
    return Text(
      context.l10n.offices_new,
      style: ClientTypography.labelSmall(context).copyWith(
        color: ClientColors.primaryFor(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
