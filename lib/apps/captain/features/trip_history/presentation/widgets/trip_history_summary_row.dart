import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

/// Lifetime totals for the history tab. Always whole-history, never filtered.
class TripHistorySummaryRow extends StatelessWidget {
  const TripHistorySummaryRow({
    super.key,
    required this.totalTrips,
    required this.totalPassengers,
  });

  final int totalTrips;
  final int totalPassengers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.check_circle_rounded,
              color: CaptainColors.success,
              label: 'رحلات',
              value: '$totalTrips',
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s16),
          Expanded(
            child: _SummaryTile(
              icon: Icons.people_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
              label: 'ركاب نُقلوا',
              value: '$totalPassengers',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return CaptainCard(
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(label, style: textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
