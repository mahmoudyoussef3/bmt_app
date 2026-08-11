import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class CaptainPickupProgressBar extends StatelessWidget {
  const CaptainPickupProgressBar({
    super.key,
    required this.boarded,
    required this.total,
  });

  final int boarded;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (boarded / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 16,
              color: CaptainColors.textSecondaryFor(context),
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            Text(
              'الركاب على المتن',
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
            const Spacer(),
            Text(
              '$boarded / $total',
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: CaptainDesignTokens.s8),
        ClipRRect(
          borderRadius: CaptainDesignTokens.brPill,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: CaptainColors.dividerFor(context),
            valueColor: const AlwaysStoppedAnimation(CaptainColors.primary),
          ),
        ),
      ],
    );
  }
}
