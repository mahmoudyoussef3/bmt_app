import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_tile.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_brand_band.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_footnote.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_rating_badge.dart';

/// One operator, drawn as a company profile card rather than a list row: a
/// tinted brand band, the logo sitting on its edge like a letterhead crest, and
/// the score in the opposite corner.
///
/// Score and name no longer share a corner. Overlapping the two turned the
/// rating into a notification dot on an avatar; separated, the card reads the
/// way a rider decides — who they are, how they are rated, where they drive.
class HomeOfficeTile extends StatelessWidget {
  const HomeOfficeTile({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  static const double width = 220;
  static const double height = 190;
  static const double _bandHeight = 72;
  static const double _logoSize = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClientCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ClientRadius.lg - 1),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeOfficeBrandBand(height: _bandHeight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      child: _Identity(office: office),
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                top: _bandHeight - (_logoSize / 2),
                start: 16,
                child: OfficeLogoTile(logoUrl: office.logoUrl, size: _logoSize),
              ),
              PositionedDirectional(
                top: 12,
                end: 12,
                child: HomeOfficeRatingBadge(office: office),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.office});

  final OfficeSummary office;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          office.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context).copyWith(
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const Spacer(),
        Divider(
          height: 1,
          thickness: 1,
          color: ClientColors.borderFor(context).withAlpha(150),
        ),
        const SizedBox(height: ClientSpacing.xs),
        HomeOfficeFootnote(office: office),
      ],
    );
  }
}
