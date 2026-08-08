import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_flow_diagram.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// Introduces EWT as the single system that replaces the scattered tools
/// [ProblemSection] described — one connected chain from a customer to
/// business growth, rather than a list of disconnected modules.
class SolutionSection extends StatelessWidget {
  const SolutionSection({super.key});

  static const _steps = [
    LandingFlowStep(icon: DashboardIcons.customers, label: 'العملاء'),
    LandingFlowStep(icon: DashboardIcons.bookingsActive, label: 'الحجوزات'),
    LandingFlowStep(icon: DashboardIcons.tripsActive, label: 'الرحلات'),
    LandingFlowStep(icon: DashboardIcons.operations, label: 'التشغيل'),
    LandingFlowStep(icon: DashboardIcons.walletActive, label: 'المالية'),
    LandingFlowStep(icon: DashboardIcons.reportsActive, label: 'التقارير'),
    LandingFlowStep(icon: DashboardIcons.trendUp, label: 'نمو الأعمال'),
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
              eyebrow: 'الحل',
              title: 'EWT تربط عمليات مكتبك في مكان واحد',
              description:
                  'من أول عميل يحجز رحلة، إلى الرحلة، إلى التشغيل اليومي، إلى '
                  'الحسابات، إلى التقارير — كل خطوة متصلة بالتي تليها.',
            ),
          ),
          const SizedBox(height: 48),
          const LandingReveal(child: LandingFlowDiagram(steps: _steps)),
        ],
      ),
    );
  }
}
