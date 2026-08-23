import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_tile.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_open_strip.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_brand_band.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_footnote.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_rating_badge.dart';

/// One operator, drawn as a company profile card rather than a list row: a
/// tinted brand band, the logo sitting on its edge like a letterhead crest, and
/// the score in the opposite corner.
///
/// Score and name do not share a corner. Overlapping the two turned the rating
/// into a notification dot on an avatar; separated, the card reads the way a
/// rider decides — who they are, how they are rated, where they drive.
///
/// It closes on the same footer strip the directory listing uses, so the rail
/// is a smaller printing of the same card rather than a different object: the
/// tile used to end on a chevron floating in whitespace, which said neither
/// what it opened nor that it opened anything.
///
/// The blurb sits directly under the name, ahead of the rating/coverage line —
/// a rider recognises a company by what it says about itself before they read
/// a number next to it.
class HomeOfficeTile extends StatelessWidget {
  const HomeOfficeTile({super.key, required this.office, required this.onTap});

  final OfficeSummary office;
  final VoidCallback onTap;

  static const double width = 230;
  static const double height = 228;
  static const double _bandHeight = 62;
  static const double _logoSize = 52;

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
                      padding: const EdgeInsets.fromLTRB(
                        ClientSpacing.sm,
                        _logoSize / 2 + ClientSpacing.xs,
                        ClientSpacing.sm,
                        ClientSpacing.xs,
                      ),
                      child: _Identity(office: office),
                    ),
                  ),
                  const OfficeOpenStrip(dense: true),
                ],
              ),
              PositionedDirectional(
                top: _bandHeight - (_logoSize / 2),
                start: ClientSpacing.sm,
                child: OfficeLogoTile(logoUrl: office.logoUrl, size: _logoSize),
              ),
              PositionedDirectional(
                top: ClientSpacing.xs + 2,
                end: ClientSpacing.xs + 2,
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
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w900, height: 1.3),
        ),
        if (office.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            office.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
        const Spacer(),
        HomeOfficeFootnote(office: office),
      ],
    );
  }
}
