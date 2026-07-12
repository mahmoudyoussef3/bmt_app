import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class AssignedTripsSectionTitle extends StatelessWidget {
  const AssignedTripsSectionTitle({super.key, required this.tripCount});

  final int tripCount;

  @override
  Widget build(BuildContext context) {
    final hasTrips = tripCount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s8),
          decoration: BoxDecoration(
            color: CaptainColors.primary.withValues(alpha: 0.1),
            borderRadius: CaptainDesignTokens.br12,
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: CaptainColors.primary,
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: Text(
            'رحلات اليوم',
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CaptainDesignTokens.s16,
            vertical: CaptainDesignTokens.s8,
          ),
          decoration: BoxDecoration(
            color: hasTrips
                ? CaptainColors.primary
                : CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br32,
            boxShadow: hasTrips
                ? CaptainDesignTokens.floatingShadow(context)
                : null,
          ),
          child: Text(
            hasTrips ? '$tripCount رحلات' : 'لا رحلات',
            style: CaptainTypography.labelMedium(context).copyWith(
              color: hasTrips
                  ? Colors.white
                  : CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
