import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_feature_card.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// The product's real capability groups, one card per module family. Kept to
/// the eight groups the brief calls out rather than enumerating every screen
/// — a visitor is meant to recognize the shape of the product here, not
/// audit its feature list.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    (
      icon: DashboardIcons.operations,
      title: 'العمليات',
      description: 'إدارة الرحلات اليومية والسائقين والمركبات والخطوط والحجوزات ومتابعة أي مشكلة تشغيلية.',
    ),
    (
      icon: DashboardIcons.customers,
      title: 'العملاء',
      description: 'سجل موحّد للعملاء يساعدك على فهم نشاطهم وسلوكهم مع المكتب.',
    ),
    (
      icon: DashboardIcons.financial,
      title: 'المالية',
      description: 'المدفوعات والمرتجعات والكاش باك ومحفظة العميل ورؤية مالية واضحة.',
    ),
    (
      icon: DashboardIcons.reports,
      title: 'التقارير',
      description: 'فهم الإيرادات والحجوزات ومعدل الإشغال والإلغاءات وأداء التشغيل.',
    ),
    (
      icon: DashboardIcons.businessOverview,
      title: 'نظرة تنفيذية',
      description: 'رؤية عالية المستوى لصحة العمل وأهم ما يحتاج انتباه صاحب المكتب.',
    ),
    (
      icon: DashboardIcons.plans,
      title: 'الترخيص والاشتراكات',
      description: 'اشترك في الخطة المناسبة لمكتبك، والوصول إلى الميزات بحسب اشتراكك.',
    ),
    (
      icon: DashboardIcons.captains,
      title: 'تطبيق الكابتن',
      description: 'ربط السائقين بعمليات المكتب من رحلة القبول حتى إنهاء الرحلة.',
    ),
    (
      icon: DashboardIcons.bookings,
      title: 'تجربة العميل',
      description: 'رحلة حجز وسفر سلسة للعميل، من البحث عن رحلة حتى إنهائها.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LandingContainer(
      maxWidth: 1160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingReveal(
            child: LandingSectionHeader(
              eyebrow: 'المنتج',
              title: 'كل ما يحتاجه مكتب النقل في نظام واحد',
              description: 'أهم قدرات EWT — والمزيد يتكشف تدريجياً كلما استخدمت المنصة.',
            ),
          ),
          const SizedBox(height: 40),
          LandingReveal(
            child: LandingCardGrid(
              children: [
                for (final feature in _features)
                  LandingFeatureCard(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
