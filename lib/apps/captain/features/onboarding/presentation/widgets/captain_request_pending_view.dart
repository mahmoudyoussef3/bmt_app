import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

/// Shown while a submitted request awaits an operations decision. The cubit
/// polls in the background; this view offers a manual refresh too.
class CaptainRequestPendingView extends StatelessWidget {
  final String phone;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;

  const CaptainRequestPendingView({
    super.key,
    required this.phone,
    required this.onRefresh,
    required this.onCancel,
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
              color: scheme.primary.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Center(child: SizedBox(width: 44, height: 44)),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'طلبك قيد المراجعة',
          textAlign: TextAlign.center,
          style: CaptainTypography.headlineMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'يقوم فريق العمليات بمراجعة بياناتك الآن. سيتم تفعيل حسابك فور '
          'الموافقة، وستنتقل تلقائياً إلى صفحتك الرئيسية.',
          textAlign: TextAlign.center,
          style: CaptainTypography.bodyMedium(
            context,
          ).copyWith(color: scheme.onSurfaceVariant, height: 1.5),
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
        const SizedBox(height: 28),
        CaptainButton(
          label: 'تحديث الحالة',
          icon: Icons.refresh_rounded,
          variant: CaptainButtonVariant.secondary,
          onPressed: onRefresh,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onCancel,
          child: const Text('إلغاء الطلب والعودة'),
        ),
      ],
    );
  }
}
