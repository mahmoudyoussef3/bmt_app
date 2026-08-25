import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// The captain's rating, in the design's neutral pill: `--surface2` behind it,
/// and the only colour is the star.
///
/// A brand-tinted pill with a brand border made the rating look like a control
/// to be tapped. It is a fact about the captain, so it is drawn the way every
/// other fact on this screen is.
class DriverProfileRatingPill extends StatelessWidget {
  const DriverProfileRatingPill({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s8,
        5,
        CaptainDesignTokens.s12,
        5,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.brPill,
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
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
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
