import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class AssignedTripsSectionTitle extends StatelessWidget {
  const AssignedTripsSectionTitle({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: CaptainTypography.titleSmall(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CaptainDesignTokens.s12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: CaptainColors.primary.withValues(alpha: 0.1),
            borderRadius: CaptainDesignTokens.br32,
          ),
          child: Text(
            '$count',
            style: CaptainTypography.labelMedium(context).copyWith(
              color: CaptainColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
