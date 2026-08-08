import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_tile.dart';
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
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: accent.withAlpha(isDark ? 20 : 10),
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
      children: [
        OfficeLogoTile(logoUrl: office.logoUrl, size: 72, raised: true),
        const SizedBox(height: ClientSpacing.md),
        Text(
          office.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingMedium(context).copyWith(
            fontWeight: FontWeight.w900,
            color: ClientColors.textPrimaryFor(context),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ClientColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: ClientColors.ratingFor(context)),
              const SizedBox(width: 4),
              Text(
                office.hasRating ? office.rating.toStringAsFixed(1) : context.l10n.offices_noRatingsYet,
                style: ClientTypography.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              if (office.hasRating) ...[
                const SizedBox(width: 6),
                Text(
                  '(${office.ratingsCount})',
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.textTertiaryFor(context),
                  ),
                ),
              ]
            ],
          ),
        ),
        if (office.description.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.md),
          Text(
            office.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
        ],
        if (office.serviceAreas.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.lg),
          OfficeServiceAreas(areas: office.serviceAreas),
        ],
      ],
    );
  }
}
