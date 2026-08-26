import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// The one card surface in the client app.
///
/// This is the design file's `CARD` constant made literal: a `--surface` fill,
/// a single `--border` hairline, a 20px radius, 16px of padding and one soft
/// drop shadow. Everything that groups content into a block on a rider screen
/// should be this widget rather than a hand-rolled [Container] — that is what
/// keeps a list of route cards, office tiles and trip rows reading as one
/// surface rather than five near-misses.
///
/// Pass [selected] for the design's chosen-option treatment (a 2px brand
/// border) used by package and payment-method pickers.
class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.useShadow = true,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool useShadow;

  /// Draws the brand border the design gives a picked option.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final innerCard = Container(
      margin: margin,
      padding: padding ?? ClientSpacing.card,
      decoration: BoxDecoration(
        color: backgroundColor ?? ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(
          color: selected
              ? ClientColors.primaryFor(context)
              : borderColor ?? ClientColors.borderFor(context),
          width: selected ? 2 : 1,
        ),
        boxShadow: useShadow ? ClientElevation.md(context) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return PressableScale(onTap: onTap, scale: 0.98, child: innerCard);
    }

    return innerCard;
  }
}
