import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/captain_day_summary.dart';

/// The day at a glance: three tiles, each a number over the word for it.
///
/// The earlier strip packed all three into one bordered box as icon-plus-inline
/// text, which made them read as a sentence to be parsed rather than three
/// figures to be scanned. Separate tiles with the number at the top of the type
/// scale is the design's shape, and it survives a glance at arm's length.
class AssignedTripsStatsStrip extends StatelessWidget {
  const AssignedTripsStatsStrip({super.key, required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // IntrinsicHeight, not `CrossAxisAlignment.stretch`: the strip is laid
        // out in an unbounded-height list, where stretch asks each tile to be
        // infinitely tall. This keeps the three tiles level when one label
        // wraps and the others do not.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Tile(value: summary.totalTrips, label: 'رحلات اليوم'),
              const SizedBox(width: 10),
              _Tile(value: summary.passengers, label: 'ركاب'),
              const SizedBox(width: 10),
              _Tile(
                value: summary.activeTrips,
                label: 'نشطة',
                highlight: summary.activeTrips > 0,
              ),
            ],
          ),
        ),
        if (summary.passengers > 0) ...[
          const SizedBox(height: CaptainDesignTokens.s12),
          _BoardingLine(summary: summary),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int value;
  final String label;

  /// A live trip is the one figure here that can need acting on, so it is the
  /// only one allowed to take colour.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: CaptainDesignTokens.s12,
          horizontal: CaptainDesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br16,
          border: CaptainDesignTokens.hairline(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              maxLines: 1,
              style: CaptainTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.w800,
                color: highlight
                    ? CaptainColors.warningFor(context)
                    : CaptainColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardingLine extends StatelessWidget {
  const _BoardingLine({required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final done = summary.boardingProgress >= 1;
    final tint = done
        ? CaptainColors.successFor(context)
        : CaptainColors.primaryInkFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: CaptainDesignTokens.hairline(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: CaptainDesignTokens.brPill,
              child: LinearProgressIndicator(
                value: summary.boardingProgress,
                minHeight: 6,
                backgroundColor: CaptainColors.surfaceAltFor(context),
                valueColor: AlwaysStoppedAnimation<Color>(tint),
              ),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Text(
            'صعد ${summary.boarded} من ${summary.passengers}',
            style: CaptainTypography.labelSmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
