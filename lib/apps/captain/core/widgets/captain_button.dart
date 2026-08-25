import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

enum CaptainButtonVariant { primary, secondary, danger, outline }

class _Icon extends StatelessWidget {
  const _Icon({
    required this.icon,
    required this.color,
    required this.mirrorInRtl,
  });

  final IconData icon;
  final Color color;
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 20, color: color);
    final flip = mirrorInRtl && Directionality.of(context) == TextDirection.rtl;
    return flip ? Transform.flip(flipX: true, child: glyph) : glyph;
  }
}

/// The design's button set.
///
/// `primary` is the only variant that fills: the brand gradient plus a tinted
/// glow beneath it, so on any screen the one thing the captain is meant to
/// press is unmistakable at a glance and through a windscreen's worth of glare.
/// Everything else is a hairline outline on the page — a screen with two filled
/// buttons has no primary action.
class CaptainButton extends StatelessWidget {
  const CaptainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CaptainButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.mirrorIconInRtl = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final CaptainButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  final double height;

  final bool mirrorIconInRtl;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    Gradient? gradient;
    Color bgColor = Colors.transparent;
    Color fgColor;
    Color? borderColor;

    switch (variant) {
      case CaptainButtonVariant.primary:
        gradient = CaptainColors.primaryGradient(context);
        fgColor = CaptainColors.onPrimary;
      case CaptainButtonVariant.secondary:
        bgColor = CaptainColors.surfaceAltFor(context);
        fgColor = CaptainColors.textPrimaryFor(context);
      case CaptainButtonVariant.danger:
        bgColor = CaptainColors.dangerFor(context);
        fgColor = Colors.white;
      case CaptainButtonVariant.outline:
        bgColor = CaptainColors.surfaceFor(context);
        fgColor = CaptainColors.textPrimaryFor(context);
        borderColor = CaptainColors.borderFor(context);
    }

    if (isDisabled) {
      gradient = null;
      bgColor = CaptainColors.surfaceAltFor(context);
      fgColor = CaptainColors.textSecondaryFor(context).withValues(alpha: 0.6);
      borderColor = null;
    }

    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
        ] else if (icon != null) ...[
          _Icon(icon: icon!, color: fgColor, mirrorInRtl: mirrorIconInRtl),
          const SizedBox(width: CaptainDesignTokens.s8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(color: fgColor, fontWeight: FontWeight.w800),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: CaptainDesignTokens.br16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s16,
        ),
        decoration: BoxDecoration(
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          borderRadius: CaptainDesignTokens.br16,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: variant == CaptainButtonVariant.primary && !isDisabled
              ? CaptainDesignTokens.glow(
                  context,
                  CaptainColors.primary,
                  alpha: 0.45,
                )
              : null,
        ),
        child: buttonContent,
      ),
    );
  }
}
