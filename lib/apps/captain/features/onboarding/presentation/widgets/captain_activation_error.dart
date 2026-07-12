import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_spacing.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Surfaces a failed attempt to establish the operational session (network,
/// server) — distinct from simply not being activated yet.
class CaptainActivationError extends StatelessWidget {
  const CaptainActivationError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainSpacing.lg),
      decoration: BoxDecoration(
        color: CaptainColors.error.withValues(alpha: 0.08),
        borderRadius: CaptainRadius.rLg,
        border: Border.all(color: CaptainColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: CaptainColors.error,
            size: 20,
          ),
          const SizedBox(width: CaptainSpacing.md),
          Expanded(
            child: Text(
              message,
              style: CaptainTypography.bodyMedium(
                context,
              ).copyWith(color: CaptainColors.textPrimaryFor(context)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
