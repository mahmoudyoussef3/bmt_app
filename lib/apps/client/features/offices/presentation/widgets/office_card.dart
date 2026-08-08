import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_tile.dart';
import 'office_rating_pill.dart';
import 'office_service_areas.dart';

/// One operator in the marketplace directory.
///
/// The card answers a rider's three questions in the order they ask them: who
/// is this company, is it any good, and does it drive where I am going — then
/// closes with the one thing they can do about it. The blurb the office wrote
/// about itself now appears here rather than only on the profile: it is the
/// only line that distinguishes two equally-rated operators at a glance.
class OfficeCard extends StatelessWidget {
  const OfficeCard({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Masthead(office: office),
          if (office.serviceAreas.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: ClientColors.borderFor(context).withAlpha(150),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OfficeServiceAreas(
                    areas: office.serviceAreas,
                    limit: 3,
                  ),
                ),
                DirectionalIcon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: ClientColors.primaryFor(context),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DirectionalIcon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: ClientColors.primaryFor(context),
              ),
            ),
          ],
        ],
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
        OfficeLogoTile(logoUrl: office.logoUrl, size: 64, raised: false),
        const SizedBox(width: 16),
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
                      style: ClientTypography.headingSmall(context).copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OfficeRatingPill(office: office),
                ],
              ),
              if (office.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  office.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
