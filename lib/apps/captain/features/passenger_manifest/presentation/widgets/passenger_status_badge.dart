import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_status_presentation.dart';

/// A passenger's boarding status, as the design draws it: one neutral
/// `--surface2` pill for every state, with the word inside carrying the colour.
///
/// Filling the pill itself would put a solid green block against a solid red
/// block in a scrolling list — the colours would fight each other and the names
/// beside them. Keeping the fill constant means the *text* is the signal, which
/// is also what survives being read at a glance in daylight.
class PassengerStatusBadge extends StatelessWidget {
  const PassengerStatusBadge({super.key, required this.status});

  final PassengerBoardingStatus status;

  @override
  Widget build(BuildContext context) {
    final foreground = status.colorFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: foreground),
          const SizedBox(width: CaptainDesignTokens.s4),
          Text(
            status.label,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: foreground,
              letterSpacing: 0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
