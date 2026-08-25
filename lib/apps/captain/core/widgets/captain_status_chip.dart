import 'package:flutter/material.dart';
import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

enum CaptainStatusVariant { info, success, warning, error, neutral }

/// A status pill in the design's idiom: one neutral `--surface2` fill for every
/// variant, and the **text** carries the colour.
///
/// The earlier chip tinted its own background and drew a matching border, so a
/// row of four statuses put four coloured rectangles on the screen and the
/// captain had to read the shapes before the words. Keeping the fill constant
/// means a list of statuses reads as a column of labels, and the one that is
/// red is the only thing that catches the eye.
class CaptainStatusChip extends StatelessWidget {
  const CaptainStatusChip({
    super.key,
    required this.label,
    this.variant = CaptainStatusVariant.neutral,
    this.icon,
  });

  final String label;
  final CaptainStatusVariant variant;
  final IconData? icon;

  Color _foreground(BuildContext context) => switch (variant) {
    CaptainStatusVariant.info => CaptainColors.primaryInkFor(context),
    CaptainStatusVariant.success => CaptainColors.successFor(context),
    CaptainStatusVariant.warning => CaptainColors.warningFor(context),
    CaptainStatusVariant.error => CaptainColors.dangerFor(context),
    CaptainStatusVariant.neutral => CaptainColors.textSecondaryFor(context),
  };

  @override
  Widget build(BuildContext context) {
    final fgColor = _foreground(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fgColor),
            const SizedBox(width: CaptainDesignTokens.s4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelSmall(
                context,
              ).copyWith(color: fgColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
