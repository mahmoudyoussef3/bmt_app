import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_status_presentation.dart';

class PassengerStatusBadge extends StatelessWidget {
  const PassengerStatusBadge({super.key, required this.status});

  final PassengerBoardingStatus status;

  @override
  Widget build(BuildContext context) {
    final emphasis = status.emphasis;
    // A cancelled booking is a dead row, so it drops to the same muted tone the
    // rest of the card uses for secondary text. Every live status keeps the one
    // primary blue; the fill weight and the icon carry the difference.
    final accent = emphasis == PassengerStatusEmphasis.muted
        ? CaptainColors.textSecondaryFor(context)
        : status.color;

    final (
      Color background,
      Color border,
      Color foreground,
    ) = switch (emphasis) {
      PassengerStatusEmphasis.solid => (
        accent,
        accent,
        CaptainColors.onPrimary,
      ),
      PassengerStatusEmphasis.tinted => (
        accent.withAlpha(28),
        accent.withAlpha(60),
        accent,
      ),
      PassengerStatusEmphasis.outlined => (
        Colors.transparent,
        accent.withAlpha(140),
        accent,
      ),
      PassengerStatusEmphasis.muted => (
        Colors.transparent,
        accent.withAlpha(80),
        accent,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: CaptainDesignTokens.br8,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: foreground),
          const SizedBox(width: CaptainDesignTokens.s4),
          Text(
            status.label,
            style: CaptainTypography.labelSmall(
              context,
            ).copyWith(color: foreground, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
