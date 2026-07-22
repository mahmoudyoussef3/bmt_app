import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// A quiet heading that sits *above* the block it names, on the page
/// background.
///
/// This is the counterpart to [CaptainListGroup] and the reason the captain
/// screens stopped looking like an admin console: the old pattern gave every
/// block a titled card with a tinted icon chip inside it, so a screen was five
/// identical framed rectangles with no hierarchy between them. Naming a group
/// from outside costs one muted line and lets the group itself stay a plain
/// surface — which is what phone apps do.
class CaptainSectionLabel extends StatelessWidget {
  const CaptainSectionLabel(this.text, {super.key, this.trailing});

  final String text;

  /// An optional counter or action aligned to the row's trailing edge.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s4,
        0,
        CaptainDesignTokens.s4,
        CaptainDesignTokens.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
