import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// A label paired with its value on one line, optionally led by an icon.
///
/// The truncation rule is the reason this is shared rather than re-inlined per
/// card: the label yields before the value does. A truncated "لوحة الترخيص"
/// still reads; a truncated plate number is useless. Neither may overflow —
/// these rows carry long values (models, plates, licence numbers) on narrow
/// phones, in Arabic, at arbitrary text scales.
class CaptainDetailRow extends StatelessWidget {
  const CaptainDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.bottomSpacing = CaptainDesignTokens.s12,
  });

  final String label;
  final String value;

  /// Omitted by callers that already carry their own leading affordance.
  final IconData? icon;

  /// Trailing gap, so stacked rows space themselves without the parent
  /// interleaving separators. Pass `0` for a standalone row.
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomSpacing),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: CaptainColors.textSecondaryFor(context),
            ),
            const SizedBox(width: CaptainDesignTokens.s12),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
