import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

/// Confirmation shown after a captain access application is submitted.
class CaptainRequestSuccessView extends StatelessWidget {
  const CaptainRequestSuccessView({
    super.key,
    required this.name,
    required this.onDone,
  });

  final String name;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final greeting = name.isEmpty ? 'Thanks!' : 'Thanks, ${name.split(' ').first}!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            tween: Tween(begin: 0.6, end: 1),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: CaptainColors.success.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: CaptainColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '$greeting Application received',
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Our operations team will review your details and reach out once '
          'your captain account is ready. This usually takes 1–2 business days.',
          textAlign: TextAlign.center,
          style: CaptainTypography.bodyMedium(context).copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        CaptainButton(label: 'Back to Sign In', onPressed: onDone),
      ],
    );
  }
}
