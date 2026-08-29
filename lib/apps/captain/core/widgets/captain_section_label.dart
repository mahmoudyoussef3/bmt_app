import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// A section heading, sized to sit *outside* the block it names.
///
/// It is deliberately smaller and quieter than the content under it: it is a
/// caption for a group, not a title competing with the rows inside.
///
/// [color] overrides the muted default for a screen that runs its headings in
/// the brand tone. Size and weight stay put either way — a heading earns its
/// rank by being small and set apart, not by shouting.
class CaptainSectionLabel extends StatelessWidget {
  const CaptainSectionLabel(this.text, {super.key, this.trailing, this.color});

  final String text;

  final Widget? trailing;

  final Color? color;

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
                color: color ?? CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
