import 'package:flutter/material.dart';
import '../theme/captain_spacing.dart';

enum CaptainButtonVariant { primary, secondary, danger, outline }

class CaptainButton extends StatelessWidget {
  const CaptainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CaptainButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CaptainButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

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
          const SizedBox(width: CaptainSpacing.md),
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: fgColor),
          const SizedBox(width: CaptainSpacing.md),
        ],
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: CaptainRadius.rLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: CaptainSpacing.xl),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: CaptainRadius.rLg,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: variant == CaptainButtonVariant.primary && onPressed != null
              ? [
                  BoxShadow(
                    color: scheme.primary.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: buttonContent,
      ),
    );
  }
}
