import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The colour key for the Trip Details seat map: your seat, still-available,
/// and taken. Mirrors the three live seat states.
class TripSeatLegend extends StatelessWidget {
  const TripSeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendDot(
          color: ClientColors.primary,
          label: 'Your seat',
          outlined: false,
        ),
        _LegendDot(
          color: ClientColors.journeyGreenLight,
          label: 'Available',
          outlined: false,
        ),
        _LegendDot(
          color: ClientColors.surfaceMutedFor(context),
          label: 'Taken',
          outlined: true,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}
