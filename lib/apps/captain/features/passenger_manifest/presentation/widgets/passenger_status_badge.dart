import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/passenger.dart';
import 'passenger_status_presentation.dart';

class PassengerStatusBadge extends StatelessWidget {
  const PassengerStatusBadge({super.key, required this.status});

  final PassengerBoardingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: CaptainDesignTokens.br8,
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        status.label,
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
