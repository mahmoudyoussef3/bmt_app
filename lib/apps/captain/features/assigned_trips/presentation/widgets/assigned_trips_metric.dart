import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// A single number in the captain's day overview (trips, active, passengers).
class AssignedTripsMetric extends StatelessWidget {
  const AssignedTripsMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: CaptainDesignTokens.s16,
          horizontal: CaptainDesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isHighlight ? color : CaptainColors.surfaceFor(context),
          borderRadius: CaptainDesignTokens.br16,
          boxShadow: isHighlight
              ? CaptainDesignTokens.floatingShadow(context)
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: isHighlight
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(CaptainDesignTokens.s8),
              decoration: BoxDecoration(
                color: isHighlight
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isHighlight ? Colors.white : color,
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s12),
            Text(
              value,
              style: CaptainTypography.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: isHighlight
                    ? Colors.white
                    : CaptainColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s4),
            Text(
              label,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: isHighlight
                    ? Colors.white.withValues(alpha: 0.9)
                    : CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
