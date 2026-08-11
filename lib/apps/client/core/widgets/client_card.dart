import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// A unified premium card component for the BMT Client App.
/// It enforces standard border radius (24px), subtle border/shadows, and clean white surface.
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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool useShadow;

  @override
  Widget build(BuildContext context) {
    final innerCard = Container(
      margin: margin,
      padding: padding ?? ClientSpacing.card,
      decoration: BoxDecoration(
        color: backgroundColor ?? ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg), 
        border: Border.all(
          color: borderColor ?? ClientColors.borderFor(context),
          width: 1,
        ),
        boxShadow: useShadow ? ClientElevation.sm(context) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: innerCard,
      );
    }

    return innerCard;
  }
}
