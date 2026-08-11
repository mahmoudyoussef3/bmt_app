import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: CaptainDesignTokens.s8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.bodySmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
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
