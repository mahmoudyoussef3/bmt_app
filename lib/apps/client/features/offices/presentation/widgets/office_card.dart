import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Masthead(office: office),
                if (office.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OfficeServiceAreas(areas: office.serviceAreas, limit: 3),
                ],
              ],
            ),
          ),
          const _OpenStrip(),
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
        OfficeLogoTile(logoUrl: office.logoUrl, size: 56, raised: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                office.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyLarge(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              if (office.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  office.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.textSecondaryFor(context),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        OfficeRatingPill(office: office),
      ],
    );
  }
}

/// The card's closing rule: a muted strip that names the destination of a tap
/// instead of leaving a bare chevron to imply it.
class _OpenStrip extends StatelessWidget {
  const _OpenStrip();

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ClientRadius.lg - 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.departure_board_rounded, size: 15, color: accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              context.l10n.offices_openProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
          DirectionalIcon(Icons.arrow_forward_rounded, size: 15, color: accent),
        ],
      ),
    );
  }
}
