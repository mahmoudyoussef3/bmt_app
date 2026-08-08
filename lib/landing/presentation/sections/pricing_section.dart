import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// EWT already prices offices through the licensing console
/// (`platform_licensing`), but that catalog is a platform-admin surface, not
/// public data — so this section never renders a number. Showing an invented
/// price would fail the "no fabricated business data" rule as surely as a
/// fake KPI would.
class PricingSection extends StatelessWidget {
  const PricingSection({super.key, required this.onContactSales});

  final VoidCallback onContactSales;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LandingContainer(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingReveal(
            child: LandingSectionHeader(
              eyebrow: 'الأسعار',
              title: 'اختر الخطة المناسبة لمكتبك',
              description:
                  'تختلف احتياجات كل مكتب حسب حجم التشغيل وعدد الرحلات والمستخدمين — '
                  'نساعدك على اختيار الخطة الأنسب لحجم عملك.',
            ),
          ),
          const SizedBox(height: 32),
          LandingReveal(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xLarge),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                    child: Icon(DashboardIcons.plansActive, color: scheme.primary, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'خطط مرنة حسب حجم عملك',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تواصل معنا لمعرفة الخطة المناسبة',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  LandingButton.primary(
                    label: 'تواصل معنا لمعرفة الخطة المناسبة',
                    onPressed: onContactSales,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
