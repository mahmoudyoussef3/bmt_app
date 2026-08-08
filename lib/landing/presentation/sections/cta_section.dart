import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';

/// The closing pitch, on the same brand-gradient lockup the dashboard home
/// banner and the client/captain hero screens use — see
/// [DashboardColors.heroGradient] for why it is one shared object rather than
/// a colour this page invents on its own.
class CtaSection extends StatelessWidget {
  const CtaSection({super.key, required this.onGetStarted, required this.onContactSales});

  final VoidCallback onGetStarted;
  final VoidCallback onContactSales;

  @override
  Widget build(BuildContext context) {
    final mobile = LandingContainer.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: DashboardColors.heroGradient(context)),
      child: LandingContainer(
        maxWidth: 800,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: mobile ? 56 : 88),
          child: LandingReveal(
            child: Column(
              children: [
                LandingSectionHeader(
                  title: 'جاهز تدير مكتبك بطريقة أذكى؟',
                  description:
                      'ابدأ باستخدام EWT واجعل تشغيل مكتب النقل، ومتابعة الأداء، '
                      'واتخاذ القرار في مكان واحد.',
                  dark: true,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.medium,
                  children: [
                    LandingButton.primary(
                      label: 'ابدأ مع EWT',
                      onPressed: onGetStarted,
                      dark: true,
                    ),
                    LandingButton.secondary(
                      label: 'تواصل معنا',
                      onPressed: onContactSales,
                      dark: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
