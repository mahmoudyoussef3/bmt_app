import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_feature_card.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// The problems a transportation office runs into *before* EWT — the
/// section that earns the right to introduce the product. Framed around
/// symptoms an owner recognizes rather than product features.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  static const _problems = [
    (
      icon: DashboardIcons.operations,
      title: 'التشغيل مشتت',
      description: 'الرحلات والحجوزات والسائقين والعملاء في أكثر من مكان.',
    ),
    (
      icon: DashboardIcons.health,
      title: 'صعوبة متابعة الأداء',
      description: 'صاحب المكتب يعرف ما يحدث، لكنه لا يعرف دائماً لماذا يحدث.',
    ),
    (
      icon: DashboardIcons.insight,
      title: 'القرارات بدون بيانات',
      description: 'الإيرادات والإشغال والإلغاءات وأداء التشغيل تحتاج إلى تحليل مستمر.',
    ),
    (
      icon: DashboardIcons.trendUp,
      title: 'نمو المكتب يصبح أصعب',
      description: 'كلما زاد عدد الرحلات والعملاء والسائقين، زادت صعوبة الإدارة اليدوية.',
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
              eyebrow: 'التحدي',
              title: 'إدارة مكتب النقل يدوياً لها حدود',
              description:
                  'مع زيادة الرحلات والعملاء، تتحول الإدارة المتفرقة من عائق بسيط '
                  'إلى خطر حقيقي على استمرار العمل بكفاءة.',
            ),
          ),
          const SizedBox(height: 40),
          LandingReveal(
            child: LandingCardGrid(
              children: [
                for (final problem in _problems)
                  LandingFeatureCard(
                    icon: problem.icon,
                    title: problem.title,
                    description: problem.description,
                    iconColor: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
