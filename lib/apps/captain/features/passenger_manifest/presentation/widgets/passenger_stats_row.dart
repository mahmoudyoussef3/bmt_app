import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/passenger_manifest_state.dart';

/// Boarding tallies and progress for the whole trip.
class PassengerStatsRow extends StatelessWidget {
  const PassengerStatsRow({super.key, required this.counts});

  final PassengerCounts counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
        CaptainDesignTokens.s24,
        CaptainDesignTokens.s16,
      ),
      child: Container(
        padding: const EdgeInsets.all(CaptainDesignTokens.s24),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br24,
          boxShadow: CaptainDesignTokens.softShadow(context),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _Stat(
                  label: 'صعد',
                  value: counts.boarded,
                  color: CaptainColors.success,
                ),
                _Stat(
                  label: 'بانتظار',
                  value: counts.pending,
                  color: CaptainColors.primary,
                ),
                _Stat(
                  label: 'غائب',
                  value: counts.absent,
                  color: CaptainColors.error,
                ),
                _Stat(
                  label: 'المتوقعون',
                  value: counts.expected,
                  color: CaptainColors.textSecondaryFor(context),
                ),
              ],
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
            _BoardingProgress(ratio: counts.boardedRatio),
          ],
        ),
      ),
    );
  }
}

class _BoardingProgress extends StatelessWidget {
  const _BoardingProgress({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CaptainDesignTokens.br8,
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 8,
        backgroundColor: CaptainColors.primary.withValues(alpha: 0.1),
        // Turning green only at a full load makes "everyone is aboard" a state
        // the captain can see without reading the numbers.
        valueColor: AlwaysStoppedAnimation<Color>(
          ratio == 1.0 ? CaptainColors.success : CaptainColors.primary,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: CaptainTypography.headlineMedium(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
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
