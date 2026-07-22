import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/captain_day_summary.dart';

/// The captain's day in one line: trips, active, passengers — plus how far
/// along boarding is overall.
///
/// Deliberately *not* a card. This was a bordered panel of three stat columns
/// separated by vertical rules, which is the KPI widget every web admin console
/// ships — and it made the home screen read as a dashboard more than anything
/// else on it. These numbers are context for the trip list below, not a report,
/// so they now sit directly on the page background under a hairline: present
/// when the captain wants them, silent when they don't.
class AssignedTripsStatsStrip extends StatelessWidget {
  const AssignedTripsStatsStrip({super.key, required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Stat(
              icon: Icons.route_rounded,
              value: '${summary.totalTrips}',
              label: 'رحلات',
            ),
            _Stat(
              icon: Icons.bolt_rounded,
              value: '${summary.activeTrips}',
              label: 'نشطة',
              color: summary.activeTrips > 0 ? CaptainColors.warning : null,
            ),
            _Stat(
              icon: Icons.people_alt_rounded,
              value: '${summary.passengers}',
              label: 'ركاب',
            ),
          ],
        ),
        if (summary.passengers > 0) ...[
          const SizedBox(height: CaptainDesignTokens.s12),
          _BoardingLine(summary: summary),
        ],
      ],
    );
  }
}

/// One number and what it counts, stated inline rather than stacked in a tile.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Set only when the number itself is worth noticing — an active trip is,
  /// a total is not. Everything else stays in the page's quiet register.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? CaptainColors.textSecondaryFor(context);

    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      color: color ?? CaptainColors.textPrimaryFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: CaptainTypography.labelMedium(context).copyWith(
                      color: CaptainColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How far along the whole day's boarding is — a hairline-thin bar, because it
/// is a background fact and not the thing the captain came here to do.
class _BoardingLine extends StatelessWidget {
  const _BoardingLine({required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final done = summary.boardingProgress >= 1;
    final tint = done ? CaptainColors.success : CaptainColors.primary;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.brPill,
            child: LinearProgressIndicator(
              value: summary.boardingProgress,
              minHeight: 4,
              backgroundColor: tint.withValues(alpha: 0.14),
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
          ),
        ),
      ],
    );
  }
}
