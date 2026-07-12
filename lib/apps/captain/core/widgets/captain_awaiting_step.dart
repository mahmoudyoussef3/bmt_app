import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_spacing.dart';
import '../theme/captain_typography.dart';

enum CaptainStepState { done, current, upcoming }

/// One row of the assignment workflow the captain is waiting inside:
/// account activated → operations assigns a trip → the trip appears here.
class CaptainAwaitingStep extends StatelessWidget {
  const CaptainAwaitingStep({
    super.key,
    required this.label,
    required this.state,
    this.isLast = false,
  });

  final String label;
  final CaptainStepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      CaptainStepState.done => CaptainColors.success,
      CaptainStepState.current => CaptainColors.primary,
      CaptainStepState.upcoming => CaptainColors.textSecondaryFor(context),
    };
    final isUpcoming = state == CaptainStepState.upcoming;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUpcoming
                    ? Colors.transparent
                    : color.withValues(alpha: 0.12),
                border: Border.all(
                  color: color.withValues(alpha: isUpcoming ? 0.35 : 1),
                  width: 1.5,
                ),
              ),
              child: Icon(
                switch (state) {
                  CaptainStepState.done => Icons.check_rounded,
                  CaptainStepState.current => Icons.more_horiz_rounded,
                  CaptainStepState.upcoming => Icons.circle_outlined,
                },
                size: 14,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: color.withValues(alpha: 0.18),
              ),
          ],
        ),
        const SizedBox(width: CaptainSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: isUpcoming
                    ? CaptainColors.textSecondaryFor(context)
                    : CaptainColors.textPrimaryFor(context),
                fontWeight: state == CaptainStepState.current
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
