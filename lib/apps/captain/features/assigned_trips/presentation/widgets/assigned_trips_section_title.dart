import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';

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
    return CaptainSectionLabel(title, trailing: _Count(count: count));
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Text(
        '$count',
        style: CaptainTypography.labelSmall(
          context,
        ).copyWith(
          color: CaptainColors.textSecondaryFor(context),
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
