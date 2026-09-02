import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// The closing conversion band — a navy-to-indigo gradient with a faint
/// console wireframe bled off the leading edge.
class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.onGetStarted,
    required this.onContact,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final headline = landingClamp(context, min: 25, vw: 3.4, max: 42);
    return Padding(
      padding: EdgeInsets.only(bottom: landingSectionGap(context)),
      child: LandingContainer(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LandingRadii.card + 10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LandingPalette.navy,
                LandingPalette.navyMid,
                LandingPalette.brandDeep,
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.76, -0.84),
                      radius: 0.9,
                      colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
                      stops: [0, 0.62],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: -40,
                bottom: -70,
                width: 420,
                child: const Opacity(opacity: 0.14, child: LandingWireframe()),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: landingClamp(context, min: 22, vw: 4, max: 60),
                  vertical: landingClamp(context, min: 38, vw: 5, max: 72),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'جاهز تدير مكتبك بشكل أذكى؟',
                        style: LandingType.heading(
                          headline,
                          color: Colors.white,
                        ).copyWith(letterSpacing: -1, height: 1.28),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'ابدأ مع EWT وخلي إدارة الرحلات والحجوزات والكباتن '
                        'والمدفوعات أسهل وأكثر تنظيمًا.',
                        style: LandingType.lead(
                          16,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 280,
                            child: LandingButton(
                              label: 'ابدأ مع EWT',
                              icon: Icons.arrow_back_rounded,
                              style: LandingButtonStyle.onDark,
                              expand: true,
                              onPressed: onGetStarted,
                            ),
                          ),
                          SizedBox(
                            width: 240,
                            child: LandingButton(
                              label: 'تواصل معنا',
                              style: LandingButtonStyle.onDarkOutline,
                              expand: true,
                              onPressed: onContact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
