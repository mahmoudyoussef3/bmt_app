import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// A concise trust section. Deliberately capability-scoped rather than
/// absolute — "controlled access", never "100% secure" — because the claim
/// has to stay true to what the product actually guarantees.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  static const _points = [
    (icon: DashboardIcons.locked, text: 'بيانات مكتبك محمية ومعزولة عن باقي المكاتب.'),
    (icon: DashboardIcons.users, text: 'وصول مضبوط لكل مستخدم بحسب دوره وصلاحياته.'),
    (icon: DashboardIcons.financial, text: 'تتبع كامل لحركة الأموال، من الدفع حتى الاسترداد.'),
    (icon: DashboardIcons.audit, text: 'سجل قابل للمراجعة لكل عملية مالية داخل النظام.'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LandingContainer(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingReveal(
            child: LandingSectionHeader(
              eyebrow: 'الأمان والموثوقية',
              title: 'وصول منضبط، وسجلات مالية يمكن الوثوق بها',
            ),
          ),
          const SizedBox(height: 36),
          LandingReveal(
            child: Wrap(
              spacing: AppSpacing.xLarge,
              runSpacing: AppSpacing.large,
              children: [
                for (final point in _points)
                  SizedBox(
                    width: 380,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(point.icon, color: scheme.primary, size: 22),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Text(
                            point.text,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
