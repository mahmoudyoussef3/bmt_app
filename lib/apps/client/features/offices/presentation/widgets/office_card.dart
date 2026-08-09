import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_tile.dart';
import 'office_open_strip.dart';
import 'office_rating_pill.dart';
import 'office_service_areas.dart';

/// One operator in the marketplace directory.
///
/// The card answers a rider's three questions in the order they ask them: who
/// is this company, is it any good, and does it drive where I am going — then
/// closes with the one thing they can do about it.
///
/// That closing move is a footer strip rather than the bare chevron it used to
/// be. A directory card is a door, and naming what is behind it ("departures &
/// routes") is what turns a list of logos into a list of shops.
class OfficeCard extends StatelessWidget {
  const OfficeCard({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClientRadius.lg - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(ClientSpacing.md),
              child: _Masthead(office: office),
            ),
            const OfficeOpenStrip(),
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OfficeLogoTile(logoUrl: office.logoUrl, size: 60, raised: false),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      office.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900, height: 1.25),
                    ),
                  ),
                  const SizedBox(width: ClientSpacing.xs),
                  OfficeRatingPill(office: office),
                ],
              ),
              if (office.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  office.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.5,
                  ),
                ),
              ],
              // Hung off the logo's column rather than the card's full width:
              // an operator with no blurb would otherwise leave a band of dead
              // space beside its crest.
              if (office.serviceAreas.isNotEmpty) ...[
                const SizedBox(height: ClientSpacing.sm),
                OfficeServiceAreas(areas: office.serviceAreas, limit: 3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
