import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Every assigned trip is done. Confirms completion instead of leaving the
/// captain on a screen full of finished trips with nothing to act on.
class CaptainDayCompleteCard extends StatelessWidget {
  const CaptainDayCompleteCard({super.key, required this.tripCount});

  final int tripCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        color: CaptainColors.success.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(
          color: CaptainColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s12),
            decoration: BoxDecoration(
              color: CaptainColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: CaptainColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أنهيت رحلات اليوم 🎉',
                  style: CaptainTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'أكملت $tripCount رحلة. استرح حتى تُسند إليك رحلة جديدة.',
                  style: CaptainTypography.bodySmall(context).copyWith(
                    color: CaptainColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
