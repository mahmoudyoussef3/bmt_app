import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

/// The focus card's crown: a full-bleed brand gradient carrying the stage in
/// white.
///
/// It used to be a 10%-alpha wash of the accent with accent-coloured text on
/// it, which is a tint pretending to be a fill — it read as a faded header and
/// the label sat barely above the contrast floor. A solid gradient with white
/// on it is the one place on the home screen brand colour is spent, and it
/// marks the single trip the captain is meant to be looking at right now.
class FocusEyebrow extends StatelessWidget {
  const FocusEyebrow({
    super.key,
    required this.isRunning,
    required this.label,
    required this.accent,
    required this.trailing,
  });

  final bool isRunning;
  final String label;
  final Color accent;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s16,
        14,
        CaptainDesignTokens.s16,
        14,
      ),
      decoration: BoxDecoration(
        gradient: CaptainColors.primaryGradient(context),
      ),
      child: Row(
        children: [
          if (isRunning) ...[
            const FocusLiveDot(color: Colors.white),
            const SizedBox(width: CaptainDesignTokens.s8),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
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

/// The crown's trailing note — the trip's status, stated in the quiet white the
/// design reserves for secondary text on a coloured fill.
class FocusCrownNote extends StatelessWidget {
  const FocusCrownNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.labelMedium(context).copyWith(
        color: Colors.white.withValues(alpha: 0.85),
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class FocusLiveDot extends StatelessWidget {
  const FocusLiveDot({super.key, required this.color, this.size = 8});

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
        color: color.withValues(alpha: 0.3),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// One fact under the route line — departure time, vehicle number.
///
/// Plain muted text with a small glyph, not a tinted pill. Two blue pills side
/// by side under the route read as buttons; these are labels, and nothing on
/// the card should look pressable except the call to action.
class FocusFact extends StatelessWidget {
  const FocusFact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'الركاب للصعود',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelMedium(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            // A tally is read left-to-right in any locale: RTL would render
            // "12 / 3" for three of twelve.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '$boarded / $total',
                style: CaptainTypography.labelMedium(context).copyWith(
                  color: CaptainColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _GradientTrack(progress: progress),
      ],
    );
  }
}

class _GradientTrack extends StatelessWidget {
  const _GradientTrack({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CaptainDesignTokens.brPill,
      child: Container(
        height: 8,
        color: CaptainColors.surfaceAltFor(context),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              // heightFactor too: without it the fill is given a tight width
              // and a loose height, collapses to zero, and the bar renders
              // empty however many riders have boarded.
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CaptainColors.primaryGradient(context),
                  borderRadius: CaptainDesignTokens.brPill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-line brief under the boarding bar: what the captain should be doing
/// at this stage.
///
/// It sits in a neutral `--surface2` well, not a tinted one. The crown and the
/// call to action are already carrying brand colour on this card; a third
/// accent surface between them turns the card into a stack of stripes.
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: CaptainDesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceAltFor(context),
        borderRadius: CaptainDesignTokens.br14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: CaptainColors.primaryInkFor(context)),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: CaptainDesignTokens.br16,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: CaptainColors.primaryGradient(context),
            borderRadius: CaptainDesignTokens.br16,
            boxShadow: CaptainDesignTokens.glow(
              context,
              CaptainColors.primary,
              alpha: 0.45,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: CaptainDesignTokens.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CaptainTypography.titleSmall(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s8),
              // `arrow_forward` carries `matchTextDirection`, so Flutter points
              // it left under RTL on its own. Hand-picking a left arrow here
              // would flip it twice and send the captain backwards.
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
