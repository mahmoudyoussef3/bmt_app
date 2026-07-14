import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/captain_day_summary.dart';

/// The captain's day in one line: trips, active, passengers — plus how far
/// along boarding is overall. Kept short so the trip list stays above the fold.
class AssignedTripsStatsStrip extends StatelessWidget {
  const AssignedTripsStatsStrip({super.key, required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s16,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.dividerFor(context)),
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Stat(
                icon: Icons.route_rounded,
                value: '${summary.totalTrips}',
                label: 'رحلات',
                color: CaptainColors.primary,
              ),
              const _Divider(),
              _Stat(
                icon: Icons.bolt_rounded,
                value: '${summary.activeTrips}',
                label: 'نشطة',
                color: CaptainColors.warning,
              ),
              const _Divider(),
              _Stat(
                icon: Icons.people_alt_rounded,
                value: '${summary.passengers}',
                label: 'ركاب',
                color: CaptainColors.success,
              ),
            ],
          ),
          if (summary.passengers > 0) ...[
            const SizedBox(height: CaptainDesignTokens.s16),
            _BoardingLine(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: CaptainColors.dividerFor(context),
    );
  }
}

class _BoardingLine extends StatelessWidget {
  const _BoardingLine({required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final done = summary.boardingProgress >= 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: CaptainDesignTokens.br8,
          child: LinearProgressIndicator(
            value: summary.boardingProgress,
            minHeight: 6,
            backgroundColor: CaptainColors.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? CaptainColors.success : CaptainColors.primary,
            ),
          ),
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        Text(
          'صعد ${summary.boarded} من أصل ${summary.passengers} راكب',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
