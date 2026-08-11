import 'package:flutter/material.dart';
import '../theme/captain_design_tokens.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color bgColor;
    Color fgColor;
    Color? borderColor;

    switch (variant) {
      case CaptainButtonVariant.primary:
        bgColor = scheme.primary;
        fgColor = scheme.onPrimary;
      case CaptainButtonVariant.secondary:
        bgColor = scheme.surfaceContainerHighest;
        fgColor = scheme.onSurface;
      case CaptainButtonVariant.danger:
        bgColor = scheme.error;
        fgColor = scheme.onError;
      case CaptainButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = scheme.onSurface;
        borderColor = scheme.outline;
    }

    if (onPressed == null) {
      bgColor = scheme.surfaceContainerHighest.withAlpha(120);
      fgColor = scheme.onSurfaceVariant.withAlpha(120);
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w700,
              ),
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
          color: bgColor,
          borderRadius: CaptainDesignTokens.br16,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow:
              variant == CaptainButtonVariant.primary && onPressed != null
              ? [
                  BoxShadow(
                    color: scheme.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: buttonContent,
      ),
    );
  }
}
