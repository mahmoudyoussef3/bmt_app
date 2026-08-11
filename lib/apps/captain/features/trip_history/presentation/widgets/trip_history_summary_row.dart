import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';

import '../utils/trip_history_palette.dart';

class TripHistorySummaryRow extends StatelessWidget {
  const TripHistorySummaryRow({
    super.key,
    required this.totalTrips,
    required this.totalPassengers,
    required this.averagePassengers,
  });

  final int totalTrips;
  final int totalPassengers;
  final int averagePassengers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s8,
      ),
      child: CaptainCard(
        child: Row(
          children: [
            _Stat(
              icon: Icons.route_rounded,
              value: '$totalTrips',
              label: 'رحلة',
              color: TripHistoryPalette.accent,
            ),
            const _Divider(),
            _Stat(
              icon: Icons.people_alt_rounded,
              value: '$totalPassengers',
              label: 'راكب نُقل',
              color: TripHistoryPalette.accentDeep,
            ),
            const _Divider(),
            _Stat(
              icon: Icons.equalizer_rounded,
              value: '$averagePassengers',
              label: 'متوسط الرحلة',
              color: TripHistoryPalette.accent,
            ),
          ],
        ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CaptainTypography.labelSmall(
              context,
            ).copyWith(color: TripHistoryPalette.neutral(context)),
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
