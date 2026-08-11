import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

class CaptainLiveSyncChip extends StatelessWidget {
  const CaptainLiveSyncChip({super.key, required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final color = isRefreshing ? CaptainColors.primary : CaptainColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s16,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRefreshing ? Icons.sync_rounded : Icons.wifi_tethering_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Flexible(
            child: Text(
              isRefreshing
                  ? 'جاري التحديث…'
                  : 'متصل بالعمليات — التحديث تلقائي',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
