import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// One verification standing — a tinted panel carrying an icon, a headline and
/// an optional supporting detail.
///
/// Distinct from `CaptainStatusChip`: that is an inline pill that labels
/// something else on its row, whereas this is a full-width panel that *is* the
/// statement, and it carries a second line of detail the chip has no room for.
class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final detailText = detail;
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CaptainTypography.labelLarge(
                    context,
                  ).copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                if (detailText != null)
                  Text(
                    detailText,
                    style: CaptainTypography.labelSmall(
                      context,
                    ).copyWith(color: CaptainColors.textSecondaryFor(context)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
