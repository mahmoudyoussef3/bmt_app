import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';

/// Pieces of [CaptainFocusCard].
///
/// These used to be painted white-on-gradient, because the card itself was a
/// full brand-blue slab sitting directly under a brand-blue app bar — two
/// identical gradients a hairline apart, which is what made the home screen
/// read as one smeared header. The card is now an ordinary surface with a
/// stage-tinted strip, so everything here is drawn in full-contrast text
/// against it.

/// The card's tinted crown: which trip this is, and its live state.
class FocusEyebrow extends StatelessWidget {
  const FocusEyebrow({
    super.key,
    required this.isRunning,
    required this.label,
    required this.accent,
    required this.trailing,
  });

  /// Drives the pulsing dot only. The wording comes from [label] so every
  /// screen names the stage identically (see `CaptainTripStageLabels`).
  final bool isRunning;
  final String label;
  final Color accent;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s12,
      ),
      color: accent.withValues(alpha: 0.10),
      child: Row(
        children: [
          if (isRunning) ...[
            FocusLiveDot(color: accent),
            const SizedBox(width: CaptainDesignTokens.s8),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(context).copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          trailing,
        ],
      ),
    );
  }
}

/// The "this trip is running" marker: a filled dot inside a soft halo.
///
/// Static on purpose. A breathing dot is the obvious choice here and it is the
/// wrong one twice over — this phone sits in a cradle for a whole shift, so a
/// permanently repeating animation on the app's primary screen is a battery
/// cost with no information in it; and a never-settling animation makes
/// `pumpAndSettle` hang for every widget test that renders a live trip. The
/// halo carries the same "live" reading for free.
class FocusLiveDot extends StatelessWidget {
  const FocusLiveDot({super.key, required this.color, this.size = 9});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// One scannable fact — an icon and its value, sized to be read at arm's
/// length rather than studied.
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
          Icon(icon, size: 17, color: CaptainColors.textSecondaryFor(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How full the bus is, as a bar plus its own count — the one number a captain
/// checks repeatedly while the doors are open.
class FocusBoardingBar extends StatelessWidget {
  const FocusBoardingBar({
    super.key,
    required this.boarded,
    required this.total,
    required this.accent,
  });

  final int boarded;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : boarded / total;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.brPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Text(
          '$boarded/$total صعدوا',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// States what the trip is waiting on, in a line the captain can act on:
/// which clock time opens boarding, or how late the departure now is.
class FocusStatusPanel extends StatelessWidget {
  const FocusStatusPanel({
    super.key,
    required this.text,
    required this.icon,
    required this.accent,
  });

  final String text;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: CaptainDesignTokens.br16,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
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

/// The card's CTA. Its own button rather than [CaptainButton] because it is
/// painted in the *stage's* colour, not the app's primary — the whole point of
/// the card is that its call to action changes character with the trip.
class FocusAction extends StatelessWidget {
  const FocusAction({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Measured against the fill rather than assumed white — the stage colours
    // run from slate through amber to blue. See `CaptainTripStagePalette`.
    final foreground = CaptainTripStagePalette.onAccent(accent);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: accent,
        borderRadius: CaptainDesignTokens.br16,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CaptainDesignTokens.br16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: foreground),
              const SizedBox(width: CaptainDesignTokens.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CaptainTypography.titleSmall(
                      context,
                    ).copyWith(color: foreground, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
