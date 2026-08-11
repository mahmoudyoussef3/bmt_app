import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../utils/trip_history_labels.dart';
import '../utils/trip_history_palette.dart';

class TripHistoryBoardingBar extends StatelessWidget {
  const TripHistoryBoardingBar({
    super.key,
    required this.boarded,
    required this.total,
  });

  final int boarded;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const _NoPassengers();

    final rate = (boarded / total).clamp(0.0, 1.0);
    final color = TripHistoryPalette.boarding(rate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_rounded, size: 14, color: color),
            const SizedBox(width: CaptainDesignTokens.s4),
            Expanded(
              child: Text(
                TripHistoryLabels.boarded(boarded, total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelMedium(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        ClipRRect(
          borderRadius: CaptainDesignTokens.brPill,
          child: LinearProgressIndicator(
            value: rate,
            minHeight: 5,
            backgroundColor: TripHistoryPalette.accent.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _NoPassengers extends StatelessWidget {
  const _NoPassengers();

  @override
  Widget build(BuildContext context) {
    final muted = TripHistoryPalette.neutral(context);

    return Row(
      children: [
        Icon(Icons.person_off_rounded, size: 14, color: muted),
        const SizedBox(width: CaptainDesignTokens.s4),
        Expanded(
          child: Text(
            'لا ركاب مسجلين',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.labelMedium(
              context,
            ).copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
