import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';

/// A small fact on a history card — the fleet code, the plate, the shortfall.
///
/// The chip is drawn in the design's neutral idiom: a `--surface2` pill whose
/// text carries the colour. It takes a [label]: a chip that is only a glyph
/// states which *kind* of fact it is and then withholds the fact itself, which
/// is what this widget was reduced to at some point — the plate chip on a
/// finished trip rendered an icon and nothing else.
class TripHistoryChip extends StatelessWidget {
  const TripHistoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isIdentifier = false,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Pins the label LTR when it is a plate or a fleet code, which RTL would
  /// otherwise reorder into a different identifier.
  final bool isIdentifier;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.labelSmall(
        context,
      ).copyWith(color: color, letterSpacing: 0, fontWeight: FontWeight.w700),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: CaptainDesignTokens.s4),
          Flexible(
            child: isIdentifier
                ? Directionality(
                    textDirection: CaptainTextDirection.ofIdentifier(label),
                    child: text,
                  )
                : text,
          ),
        ],
      ),
    );
  }
}
