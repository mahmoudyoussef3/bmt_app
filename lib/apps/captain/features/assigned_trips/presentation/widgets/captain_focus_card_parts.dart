import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Pieces of [CaptainFocusCard] — all painted on the primary gradient.

class FocusEyebrow extends StatelessWidget {
  const FocusEyebrow({super.key, required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRunning) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
        ],
        Text(
          isRunning ? 'رحلتك الحالية' : 'رحلتك القادمة',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class FocusFact extends StatelessWidget {
  const FocusFact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White-on-primary CTA — the focus card's own button, since [CaptainButton]
/// styles itself against the scaffold surface, not a coloured card.
class FocusAction extends StatelessWidget {
  const FocusAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: CaptainDesignTokens.br16,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CaptainDesignTokens.br16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: CaptainColors.primary),
              const SizedBox(width: CaptainDesignTokens.s8),
              Text(
                label,
                style: CaptainTypography.titleSmall(context).copyWith(
                  color: CaptainColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
