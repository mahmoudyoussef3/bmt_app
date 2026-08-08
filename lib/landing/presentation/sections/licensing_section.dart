import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';
import '../widgets/landing_shot.dart';

/// Multi-office / SaaS capability, described in business terms. The brief is
/// explicit that RLS/RPC/Postgres never reach a landing-page visitor — every
/// bullet here is the *value* of a technical guarantee, not the mechanism.
class LicensingSection extends StatelessWidget {
  const LicensingSection({super.key});

  static const _points = [
    (
      icon: DashboardIcons.platformOffices,
      title: 'عزل بيانات كل مكتب',
      description: 'بيانات مكتبك مستقلة تماماً عن أي مكتب آخر على المنصة.',
    ),
    (
      icon: DashboardIcons.users,
      title: 'أدوار وصلاحيات',
      description: 'كل مستخدم في لوحة التحكم يرى ويتصرف فقط بحسب دوره المحدد.',
    ),
    (
      icon: DashboardIcons.plans,
      title: 'ترخيص حسب الميزات',
      description: 'الوحدات المتاحة لمكتبك مرتبطة بخطة اشتراكك.',
    ),
    (
      icon: DashboardIcons.usage,
      title: 'حدود استخدام واضحة',
      description: 'تعرف بدقة ما هو متاح ضمن اشتراكك الحالي دون مفاجآت.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return LandingContainer(
      maxWidth: 1160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _Intro()),
                    const SizedBox(width: 56),
                    Expanded(child: LandingReveal(child: _PointList())),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Intro(),
                    const SizedBox(height: AppSpacing.xLarge),
                    LandingReveal(child: _PointList()),
                  ],
                ),
          const SizedBox(height: 48),
          const LandingReveal(
            child: LandingShot(
              asset: 'ewt-shot-plans',
              caption: 'الخطط والباقات — ما يفتحه كل اشتراك من وحدات المنصة.',
              maxWidth: 940,
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const LandingReveal(
      child: LandingSectionHeader(
        eyebrow: 'مصممة لأكثر من مكتب',
        title: 'منصة واحدة، وصول آمن ومنضبط لكل مكتب',
        alignStart: true,
        description:
            'سواء كان لديك مكتب واحد أو عدة مكاتب، EWT مبنية لتمنح كل مكتب '
            'مساحته الخاصة، وكل مستخدم صلاحياته الخاصة.',
      ),
    );
  }
}

class _PointList extends StatelessWidget {
  const _PointList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final point in LicensingSection._points)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.large),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(point.icon, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        point.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
