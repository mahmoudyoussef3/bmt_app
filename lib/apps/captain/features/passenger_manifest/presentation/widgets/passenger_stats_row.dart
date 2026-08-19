import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/passenger_manifest_state.dart';

class PassengerStatsRow extends StatelessWidget {
  const PassengerStatsRow({super.key, required this.counts});

  final PassengerCounts counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br16,
          boxShadow: CaptainDesignTokens.softShadow(context),
        ),
        child: Column(
          children: [
            // The three live tallies share one colour on purpose — their icons
            // and labels say which is which, and a row that recolours itself as
            // boarding progresses is noise the captain has to re-read.
            Row(
              children: [
                _Stat(
                  icon: Icons.check_circle_rounded,
                  label: 'صعد',
                  value: counts.boarded,
                ),
                _Stat(
                  icon: Icons.hourglass_top_rounded,
                  label: 'بانتظار',
                  value: counts.pending,
                ),
                _Stat(
                  icon: Icons.person_off_rounded,
                  label: 'غائب',
                  value: counts.absent,
                ),
                _Stat(
                  icon: Icons.people_alt_rounded,
                  label: 'المتوقعون',
                  value: counts.expected,
                  muted: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
        minHeight: 6,
        backgroundColor: CaptainColors.primary.withValues(alpha: 0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(CaptainColors.primary),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final secondary = CaptainColors.textSecondaryFor(context);
    final accent = muted ? secondary : CaptainColors.primary;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: secondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.labelSmall(
                    context,
                  ).copyWith(color: secondary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
