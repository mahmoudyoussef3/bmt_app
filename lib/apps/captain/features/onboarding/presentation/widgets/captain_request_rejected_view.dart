import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

class CaptainRequestRejectedView extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onBackToLogin;

  const CaptainRequestRejectedView({
    super.key,
    required this.reason,
    required this.onRetry,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: scheme.error.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_gmailerrorred_rounded,
              color: scheme.error,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'لم يتم قبول طلبك',
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.error.withAlpha(16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.error.withAlpha(60)),
          ),
          child: Text(
            reason,
            textAlign: TextAlign.center,
            style: CaptainTypography.bodyMedium(context).copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 28),
        CaptainButton(label: 'تعديل الطلب وإعادة المحاولة', onPressed: onRetry),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBackToLogin,
          child: const Text('العودة لتسجيل الدخول'),
        ),
      ],
    );
  }
}
