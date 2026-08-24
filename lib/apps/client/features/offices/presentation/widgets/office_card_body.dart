import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../domain/entities/office_summary.dart';
import 'office_hero_banner.dart';
import 'office_location_line.dart';
import 'office_rating_row.dart';
import 'office_routes_line.dart';

/// The identity content shared by every place a rider meets one operator: the
/// Home rail ([HomeOfficeTile]) and the offices directory ([OfficeCard]) are
/// the same card at two sizes, not two different objects, so a company is
/// recognisable as itself wherever a rider meets it.
///
/// Read top to bottom in the order a rider asks: who is this (photo + name),
/// where does it drive and is it any good (the info row, the two facts pushed
/// to opposite ends so each is read on its own), what does it say about itself
/// (the blurb), and how much does it run (the route count).
class OfficeCardBody extends StatelessWidget {
  const OfficeCardBody({
    super.key,
    required this.office,
    required this.heroHeight,
    this.dense = false,
  });

  final OfficeSummary office;
  final double heroHeight;

  /// Tighter type and inset for the Home rail's narrower tile; the full
  /// directory card gets the roomier defaults.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final inset = dense ? ClientSpacing.xs : ClientSpacing.sm;

    final info = Padding(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (office.serviceAreas.isNotEmpty)
                Flexible(child: OfficeLocationLine(areas: office.serviceAreas)),
              const SizedBox(width: ClientSpacing.xs),
              Flexible(child: OfficeRatingRow(office: office, compact: true)),
            ],
          ),
          if (office.description.isNotEmpty) ...[
            SizedBox(height: dense ? 6 : 8),
            Text(
              office.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (dense
                          ? ClientTypography.labelSmall(context)
                          : ClientTypography.bodySmall(context))
                      .copyWith(
                        color: ClientColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
            ),
          ],
          SizedBox(height: dense ? 8 : 10),
          OfficeRoutesLine(count: office.routesCount, dense: dense),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OfficeHeroBanner(office: office, height: heroHeight, dense: dense),
        dense ? Expanded(child: info) : info,
      ],
    );
  }
}
