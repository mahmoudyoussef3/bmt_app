import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// Pieces of [CaptainFocusCard] — all painted on the primary gradient.

class FocusEyebrow extends StatelessWidget {
  const FocusEyebrow({super.key, required this.isRunning, required this.label});

  /// Drives the live dot only. The wording comes from [label] so every screen
  /// names the stage identically (see `CaptainTripStageLabels`).
  final bool isRunning;
  final String label;

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
          label,
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

/// States what the trip is waiting on, in a line the captain can act on:
/// which clock time opens boarding, or how late the departure now is.
class FocusStatusPill extends StatelessWidget {
  const FocusStatusPill({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
