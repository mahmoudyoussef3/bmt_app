import 'package:flutter/material.dart';
import '../theme/captain_design_tokens.dart';

enum CaptainStatusVariant { info, success, warning, error, neutral }

class CaptainStatusChip extends StatelessWidget {
  const CaptainStatusChip({
    super.key,
    required this.label,
    this.variant = CaptainStatusVariant.neutral,
    this.icon,
  });

  final String label;
  final CaptainStatusVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color fgColor;
    Color bgColor;

    switch (variant) {
      case CaptainStatusVariant.info:
        fgColor = Colors.blue;
        bgColor = Colors.blue.withAlpha(25);
      case CaptainStatusVariant.success:
        fgColor = Colors.green;
        bgColor = Colors.green.withAlpha(25);
      case CaptainStatusVariant.warning:
        fgColor = Colors.orange;
        bgColor = Colors.orange.withAlpha(25);
      case CaptainStatusVariant.error:
        fgColor = scheme.error;
        bgColor = scheme.error.withAlpha(25);
      case CaptainStatusVariant.neutral:
        fgColor = scheme.onSurfaceVariant;
        bgColor = scheme.surfaceContainerHighest;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: fgColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: CaptainDesignTokens.s4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
