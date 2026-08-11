import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class NewAssignmentsBanner extends StatelessWidget {
  const NewAssignmentsBanner({
    super.key,
    required this.count,
    required this.onAcknowledge,
  });

  final int count;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.warning.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s8),
            decoration: BoxDecoration(
              color: CaptainColors.warning.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fiber_new_rounded,
              color: CaptainColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              'أُسندت إليك $count رحلة جديدة',
              style: CaptainTypography.labelLarge(context).copyWith(
                fontWeight: FontWeight.w800,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
          ),
          TextButton(onPressed: onAcknowledge, child: const Text('تم')),
        ],
      ),
    );
  }
}
