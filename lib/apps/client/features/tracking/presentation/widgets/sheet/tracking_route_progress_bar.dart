import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// How far along the route the vehicle is, plus how many stops are still to
/// come. Animated, so a fix that advances progress reads as movement rather
/// than a jump.
class TrackingRouteProgressBar extends StatelessWidget {
  const TrackingRouteProgressBar({
    super.key,
    required this.fraction,
    required this.remainingLabel,
  });

  final double fraction;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: ClientColors.surfaceMutedFor(context),
              valueColor: AlwaysStoppedAnimation(
                ClientColors.primaryFor(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          remainingLabel,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}
