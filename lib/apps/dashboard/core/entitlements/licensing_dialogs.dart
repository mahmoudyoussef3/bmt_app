import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../theme/dashboard_colors.dart';
import '../theme/dashboard_icons.dart';
import 'entitlement_context.dart';
import 'licensing_failure.dart';

/// The upgrade moment.
///
/// Because the server carries the whole verdict across in the exception detail,
/// the block can be specific: the named limit, the real numbers, and the plan
/// that lifts it. Never a toast, and never the words `quota_exceeded`.
///
/// Returns nothing: there is no self-service checkout in V1 (§17.2 — checkout
/// without a payment gateway is a lie), so the call to action is contact.
Future<void> showLicensingRefusal(
  BuildContext context, {
  required LicensingFailure failure,
  EntitlementContext? entitlements,
}) {
  final feature = failure.featureKey == null
      ? null
      : entitlements?.feature(failure.featureKey!);

  final blocker = failure.blockedBy == null
      ? null
      : entitlements?.feature(failure.blockedBy!);

  return showDialog<void>(
    context: context,
    builder: (context) => _LicensingRefusalDialog(
      failure: failure,
      featureNameAr: feature?.nameAr ?? failure.featureNameAr,
      unitAr: feature?.unitAr ?? '',
      blockerNameAr: blocker?.nameAr ?? failure.blockedBy,
      planNameAr: entitlements?.license.planNameAr,
    ),
  );
}

class _LicensingRefusalDialog extends StatelessWidget {
  const _LicensingRefusalDialog({
    required this.failure,
    this.featureNameAr,
    this.unitAr = '',
    this.blockerNameAr,
    this.planNameAr,
  });

  final LicensingFailure failure;
  final String? featureNameAr;
  final String unitAr;
  final String? blockerNameAr;
  final String? planNameAr;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(
        failure.isQuota ? DashboardIcons.reports : DashboardIcons.settings,
        color: scheme.primary,
        size: 28,
      ),
      title: Text(
        failure.isQuota ? 'وصلت إلى حد الباقة' : 'ميزة غير متاحة في باقتك',
        textAlign: TextAlign.center,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              failure.message,
              style: text.bodyMedium?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: DashboardColors.well(context),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: DashboardColors.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (featureNameAr != null)
                    _row(
                      context,
                      featureNameAr!,
                      failure.isQuota && failure.limit != null
                          ? '${failure.used ?? 0} / ${failure.limit}'
                                '${unitAr.isEmpty ? '' : ' $unitAr'}'
                          : 'غير مفعّلة',
                    ),
                  if (planNameAr != null && planNameAr!.isNotEmpty)
                    _row(context, 'باقتك الحالية', planNameAr!),
                  if (blockerNameAr != null)
                    _row(context, 'يتطلب تفعيل', blockerNameAr!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              
              failure.isQuota
                  ? 'لم يُحذف أو يُعطَّل أي عنصر قائم — الحد يمنع الإضافة الجديدة فقط. '
                        'للحصول على حد أعلى تواصل مع إدارة المنصة.'
                  : 'لترقية الباقة تواصل مع إدارة المنصة.',
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
          Text(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// The banner an office sees while it owes the platform something.
///
/// Shown for every state in [LicenseSummary.needsAttention] — including the two
/// that change nothing operationally. `past_due` and `grace` are fully working
/// states by design, and telling the office early is what makes suspension
/// avoidable rather than a surprise.
class LicenseBanner extends StatelessWidget {
  const LicenseBanner({super.key, required this.license, this.onOpenBilling});

  final LicenseSummary license;
  final VoidCallback? onOpenBilling;

  @override
  Widget build(BuildContext context) {
    if (!license.needsAttention && !_trialEndingSoon) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final urgent = license.isHeld || license.status == 'grace';
    final accent = urgent ? scheme.error : scheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(DashboardIcons.notifications, color: accent, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardColors.mutedInk(context),
                  ),
                ),
              ],
            ),
          ),
          if (onOpenBilling != null)
            TextButton(
              onPressed: onOpenBilling,
              child: const Text('الباقة والفوترة'),
            ),
        ],
      ),
    );
  }

  bool get _trialEndingSoon {
    final left = license.trialDaysLeft;
    return license.isTrialing && left != null && left <= 7;
  }

  String get _title => switch (license.status) {
    'trialing' => 'تنتهي فترتك التجريبية قريبًا',
    'past_due' => 'فاتورة اشتراك متأخرة',
    'grace' => 'مهلة أخيرة قبل تقييد الحساب',
    'suspended' => 'الحساب في وضع القراءة فقط',
    'cancelled' => 'تم إلغاء الترخيص',
    'expired' => 'انتهى الترخيص',
    _ => 'حالة الاشتراك',
  };

  String get _body => switch (license.status) {
    'trialing' =>
      'باقٍ ${license.trialDaysLeft ?? 0} يوم. تواصل مع المنصة لاختيار باقة.',
    'past_due' => 'الحساب يعمل بالكامل. سدّد الفاتورة لتجنّب التقييد.',
    'grace' =>
      'سيتحوّل الحساب إلى وضع القراءة فقط قريبًا إن لم تُسدَّد الفاتورة.',
    
    'suspended' || 'cancelled' =>
      'لا يمكن إنشاء رحلات أو سائقين أو خطوط جديدة. التذاكر المُباعة والرحلات '
          'الجارية ودخول الكباتن تعمل كالمعتاد.',
    'expired' => 'جدّد الاشتراك لاستئناف الإنشاء. لم يُحذف أي بيان.',
    _ => '',
  };
}
