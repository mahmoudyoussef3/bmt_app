import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';

/// A card in the design's flat idiom: `--surface` behind a 1px `--border`.
///
/// The border is what separates the card from the page, not a drop shadow — a
/// screen is normally four or five of these stacked, and giving each one a
/// shadow turns the list into a pile of floating tiles. Pass [elevated] only
/// for the one card on a screen that genuinely sits above the others.
class CaptainCard extends StatelessWidget {
  const CaptainCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CaptainDesignTokens.s16),
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = CaptainDesignTokens.br20,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius borderRadius;

  /// Lifts the card off the page with a soft shadow. Off by default.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? CaptainColors.surfaceFor(context),
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? CaptainColors.borderFor(context),
        ),
        boxShadow: elevated ? CaptainDesignTokens.softShadow(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
