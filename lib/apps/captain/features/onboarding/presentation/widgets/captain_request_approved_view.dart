import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

/// Approval confirmation. "Continue" establishes the local session and enters
/// the captain's home.
class CaptainRequestApprovedView extends StatelessWidget {
  final String name;
  final String phone;
  final bool entering;
  final VoidCallback onContinue;

  const CaptainRequestApprovedView({
    super.key,
    required this.name,
    required this.phone,
    required this.onContinue,
    this.entering = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = name.trim().isEmpty ? '' : name.trim().split(' ').first;

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
              child: const Center(
                child: Icon(Icons.verified_rounded,
                    color: CaptainColors.success, size: 56),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          first.isEmpty ? 'تم قبول طلبك 🎉' : 'أهلاً $first، تم قبول طلبك 🎉',
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'أصبح حسابك مفعّلاً. تابع للدخول إلى صفحتك الرئيسية والبدء في '
          'استقبال الرحلات.',
          textAlign: TextAlign.center,
          style: CaptainTypography.bodyMedium(context).copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            phone,
            textAlign: TextAlign.center,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: CaptainColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 32),
        CaptainButton(
          label: entering ? 'جارٍ الدخول...' : 'متابعة إلى حسابي',
          isLoading: entering,
          onPressed: entering ? null : onContinue,
        ),
      ],
    );
  }
}
