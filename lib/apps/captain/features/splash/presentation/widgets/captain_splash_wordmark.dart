import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

class CaptainSplashWordmark extends StatelessWidget {
  const CaptainSplashWordmark({super.key, required this.reveal});

  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Easy',
                    style: CaptainTypography.displayMedium(context).copyWith(
                      color: CaptainColors.textPrimaryFor(context),
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: 'Way',
                    style: CaptainTypography.displayMedium(
                      context,
                    ).copyWith(color: scheme.primary, height: 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _RolePill(),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withAlpha(50)),
      ),
      child: Text(
        'كابتن',
        style: CaptainTypography.labelMedium(
          context,
        ).copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
