import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// How every operator card ends: a tinted footer naming what is behind it.
///
/// A card is a door, and "departures & routes" is what turns a list of logos
/// into a list of shops — a bare chevron left riders guessing whether a tile
/// opened anything at all.
///
/// Shared by the directory listing and Home's rail so an operator closes the
/// same way wherever a rider meets it. [dense] drops the leading glyph for the
/// narrow rail tile, where the label needs the width more than the decoration.
class OfficeOpenStrip extends StatelessWidget {
  const OfficeOpenStrip({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? ClientSpacing.sm : ClientSpacing.md,
        vertical: dense ? ClientSpacing.xs : ClientSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
      ),
      child: Row(
        children: [
          if (!dense) ...[
            Icon(Icons.departure_board_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              context.l10n.offices_openProfile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: accent, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: ClientSpacing.xs),
          DirectionalIcon(
            Icons.arrow_forward_rounded,
            size: dense ? 14 : 16,
            color: accent,
          ),
        ],
      ),
    );
  }
}
