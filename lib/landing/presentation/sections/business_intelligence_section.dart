import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';
import '../widgets/landing_shot.dart';

/// EWT positioned as more than an operations tool: the questions an owner
/// actually asks about their business, framed as questions rather than as
/// invented sample numbers. The figures visible in the screenshots below are
/// the showcase dataset the marketing captures run against — a real console
/// rendering controlled demo data, never a claim about a real office.
class BusinessIntelligenceSection extends StatelessWidget {
  const BusinessIntelligenceSection({super.key});

  static const _questions = [
    (icon: DashboardIcons.health, text: 'كيف أداء المكتب اليوم؟'),
    (icon: DashboardIcons.ranking, text: 'ما الخطوط الأكثر نجاحاً؟'),
    (icon: DashboardIcons.attention, text: 'أين توجد المشاكل؟'),
    (icon: DashboardIcons.trend, text: 'كيف تغيرت الإيرادات؟'),
    (icon: DashboardIcons.occupancy, text: 'ما معدل الإشغال؟'),
    (icon: DashboardIcons.incident, text: 'أين تزداد الإلغاءات؟'),
    (icon: DashboardIcons.insight, text: 'ما الذي يحتاج إلى اهتمام؟'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: LandingContainer(
        maxWidth: 1160,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LandingReveal(
                child: LandingSectionHeader(
                  eyebrow: 'ذكاء الأعمال',
                  title: 'EWT ليست أداة تشغيل فقط',
                  description:
                      'المنصة تساعدك على فهم عملك، لا فقط تشغيله — من نظرة تنفيذية '
                      'واحدة إلى تقارير تفصيلية، الأسئلة التي تشغل بال صاحب المكتب '
                      'كل يوم لها مكان تُجاب فيه.',
                ),
              ),
              const SizedBox(height: 40),
              LandingReveal(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.large,
                  runSpacing: AppSpacing.large,
                  children: [
                    for (final question in _questions)
                      _QuestionCard(icon: question.icon, text: question.text),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const LandingReveal(
                child: LandingShot(
                  asset: 'ewt-shot-overview',
                  caption: 'نظرة تنفيذية — مؤشرات اليوم وصحة النشاط في شاشة واحدة.',
                  maxWidth: 940,
                ),
              ),
              const SizedBox(height: 40),
              const LandingReveal(
                child: LandingShot(
                  asset: 'ewt-shot-analytics',
                  caption: 'التحليلات المالية — سلوك الإيراد خلال الفترة، لا رقم واحد.',
                  maxWidth: 940,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 320,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
