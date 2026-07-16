import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Rating and its plain-language reading in one pill — the qualitative label a
/// captain actually reads, next to the number it comes from.
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
        color: Colors.white.withAlpha(38),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: CaptainColors.rating),
          const SizedBox(width: CaptainDesignTokens.s4),
          Text(
            '${rating.toStringAsFixed(1)} · ${_ratingLabel(rating)}',
            style: CaptainTypography.labelMedium(
              context,
            ).copyWith(color: CaptainColors.onPrimary),
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
