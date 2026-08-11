import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class DriverProfileRatingPill extends StatelessWidget {
  const DriverProfileRatingPill({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s4,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.primary.withAlpha(20),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: CaptainColors.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: CaptainColors.rating),
          const SizedBox(width: CaptainDesignTokens.s4),
          Flexible(
            child: Text(
              '${rating.toStringAsFixed(1)} · ${_ratingLabel(rating)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: CaptainColors.textPrimaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 4.5) return 'ممتاز';
    if (r >= 4.0) return 'جيد جداً';
    if (r >= 3.5) return 'جيد';
    if (r >= 3.0) return 'مقبول';
    return 'بحاجة لتحسين';
  }
}
