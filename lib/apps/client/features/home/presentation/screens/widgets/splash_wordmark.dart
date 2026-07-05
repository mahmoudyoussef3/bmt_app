import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The rounded, elevated brand tile shown at the center of the splash.
class SplashBrandMark extends StatelessWidget {
  const SplashBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: ClientColors.primaryGradientFor(context),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(90),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.route_rounded,
        color: ClientColors.textInverse,
        size: 44,
      ),
    );
  }
}

/// The "EasyWay" wordmark that fades in and slides up during the intro.
class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key, required this.reveal});

  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        return Opacity(
          opacity: reveal.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - reveal.value)),
            child: child,
          ),
        );
      },
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Easy',
              style: ClientTypography.displayLarge(context).copyWith(
                color: ClientColors.textPrimaryFor(context),
                height: 1,
              ),
            ),
            TextSpan(
              text: 'Way',
              style: ClientTypography.displayLarge(
                context,
              ).copyWith(color: ClientColors.primaryFor(context), height: 1),
            ),
          ],
        ),
      ),
    );
  }
}
