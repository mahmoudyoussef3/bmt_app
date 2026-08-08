import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_tile.dart';
import 'office_rating_row.dart';
import 'office_service_areas.dart';

/// The profile masthead: who this operator is, how riders rate it, where it
/// drives — and, once the profile has loaded, how much it is selling.
///
/// The counts live inside this card rather than in a separate pill row beneath
/// it. They are part of the operator's identity on a marketplace ("four
/// corridors, twelve departures"), and a floating row of counted chips read as
/// a second, competing header.
class OfficeProfileHeader extends StatelessWidget {
  const OfficeProfileHeader({super.key, required this.office, this.stats});

  final OfficeSummary office;

  /// The stat strip, or null while the profile's lists are still loading —
  /// zeros that are about to change are worse than no figure at all.
  final Widget? stats;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: ClientElevation.sm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(ClientSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  accent.withAlpha(isDark ? 44 : 24),
                  accent.withAlpha(0),
                ],
              ),
            ),
            child: _Identity(office: office),
          ),
          if (stats case final Widget strip) strip,
        ],
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
        Row(
          children: [
            OfficeLogoTile(logoUrl: office.logoUrl, size: 68),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.headingMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  OfficeRatingRow(office: office),
                ],
              ),
            ),
          ],
        ),
        if (office.description.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.sm),
          Text(
            office.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.55,
            ),
          ),
        ],
        if (office.serviceAreas.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.sm),
          OfficeServiceAreas(areas: office.serviceAreas),
        ],
      ],
    );
  }
}
