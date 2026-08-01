import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/office_summary.dart';
import 'office_logo_avatar.dart';
import 'office_rating_row.dart';

/// What this office publishes, counted — the masthead's bottom band.
typedef OfficeProfileCounts = ({int departures, int routes, int packages});

/// The profile masthead: who this operator is, how riders rate it, and — once
/// the profile has loaded — the size of what it is selling.
///
/// The counts matter as much as the identity: they tell a rider whether it is
/// worth scrolling before they scroll, and they turn the sections below into a
/// known quantity rather than an open-ended list.
class OfficeProfileHeader extends StatelessWidget {
  const OfficeProfileHeader({super.key, required this.office, this.counts});

  final OfficeSummary office;

  /// Null while the profile is still loading; the band is simply absent then
  /// rather than showing zeros that are about to change.
  final OfficeProfileCounts? counts;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final band = counts;

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
                  accent.withAlpha(isDark ? 38 : 22),
                  accent.withAlpha(0),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    OfficeLogoAvatar(logoUrl: office.logoUrl, size: 60),
                    const SizedBox(width: ClientSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            office.name,
                            style: ClientTypography.headingMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
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
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
                if (office.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: ClientSpacing.sm),
                  Wrap(
                    spacing: ClientSpacing.xs,
                    runSpacing: ClientSpacing.xs,
                    children: [
                      for (final area in office.serviceAreas)
                        _ServiceAreaChip(label: area),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (band != null) ...[
            Divider(height: 1, color: ClientColors.borderFor(context)),
            _CountsBand(counts: band),
          ],
        ],
      ),
    );
  }
}

class _ServiceAreaChip extends StatelessWidget {
  const _ServiceAreaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Three numbers on one line — what the rest of the screen contains.
class _CountsBand extends StatelessWidget {
  const _CountsBand({required this.counts});

  final OfficeProfileCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.sm),
      child: Row(
        children: [
          _Count(value: counts.departures, label: l10n.offices_statDepartures),
          const _BandDivider(),
          _Count(value: counts.routes, label: l10n.offices_statRoutes),
          const _BandDivider(),
          _Count(value: counts.packages, label: l10n.offices_statPackages),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: ClientTypography.headingSmall(context).copyWith(
              fontWeight: FontWeight.w900,
              color: value == 0
                  ? ClientColors.textTertiaryFor(context)
                  : ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _BandDivider extends StatelessWidget {
  const _BandDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: ClientColors.borderFor(context),
    );
  }
}
