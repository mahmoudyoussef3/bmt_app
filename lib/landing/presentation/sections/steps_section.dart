import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «ابدأ استخدام EWT في خطوات بسيطة» — the four-step onboarding, on navy.
class StepsSection extends StatelessWidget {
  const StepsSection({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LandingPalette.navy,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -1),
                  radius: 0.95,
                  colors: [Color(0x422563EB), Color(0x002563EB)],
                  stops: [0, 0.65],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: landingSectionGap(context)),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LandingSectionIntro(
                    headline: 'ابدأ استخدام EWT في خطوات بسيطة',
                    maxWidth: 720,
                    onDark: true,
                    headlineMin: 24,
                    headlineMax: 38,
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 26, vw: 3.5, max: 42),
                  ),
                  LandingAutoGrid(
                    minItemWidth: 230,
                    spacing: 13,
                    children: [
                      for (final step in LandingContent.steps)
                        _StepCard(
                          number: step.num,
                          icon: step.icon,
                          title: step.title,
                          body: step.body,
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  LandingButton(
                    label: 'ابدأ مع EWT',
                    icon: Icons.arrow_back_rounded,
                    height: 52,
                    style: LandingButtonStyle.onDark,
                    onPressed: onGetStarted,
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                number,
                style: LandingType.label(
                  13,
                  color: LandingPalette.onNavyAccent,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: LandingType.cardTitle(16.5, color: Colors.white)),
          const SizedBox(height: 7),
          Text(
            body,
            style: LandingType.cardBody(
              13.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
