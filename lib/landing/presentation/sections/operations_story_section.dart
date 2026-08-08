import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_flow_diagram.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';
import '../widgets/landing_shot.dart';

/// The core value story, told as one chain: running the office is what
/// *generates* the data that [BusinessIntelligenceSection] turns into
/// decisions. Pairs with that section rather than repeating it — this is the
/// process, that is the payoff.
class OperationsStorySection extends StatelessWidget {
  const OperationsStorySection({super.key});

  static const _steps = [
    LandingFlowStep(icon: DashboardIcons.operations, label: 'تشغيل الأعمال'),
    LandingFlowStep(icon: DashboardIcons.activity, label: 'جمع البيانات'),
    LandingFlowStep(icon: DashboardIcons.businessOverview, label: 'فهم الأداء'),
    LandingFlowStep(icon: DashboardIcons.attention, label: 'اكتشاف المشاكل'),
    LandingFlowStep(icon: DashboardIcons.insight, label: 'قرارات أفضل'),
    LandingFlowStep(icon: DashboardIcons.trendUp, label: 'نمو الأعمال'),
  ];

  @override
  Widget build(BuildContext context) {
    return LandingContainer(
      maxWidth: 1000,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingReveal(
            child: LandingSectionHeader(
              eyebrow: 'كيف تعمل EWT',
              title: 'من تشغيل يومي إلى قرار أفضل',
              description: 'كل رحلة وحجز وعملية دفع تتحول إلى بيانات، والبيانات تتحول إلى قرار.',
            ),
          ),
          const SizedBox(height: 48),
          const LandingReveal(child: LandingFlowDiagram(steps: _steps)),
          const SizedBox(height: 48),
          const LandingReveal(
            child: LandingShot(
              asset: 'ewt-shot-liveops',
              caption:
                  'العمليات المباشرة — الرحلات الجارية الآن، صحة تتبّع كل مركبة، '
                  'والبلاغات المفتوحة من الكباتن.',
              maxWidth: 980,
            ),
          ),
        ],
      ),
    );
  }
}
