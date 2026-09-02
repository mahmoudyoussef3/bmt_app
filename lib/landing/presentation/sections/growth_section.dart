import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «ابدأ منظمًا... وكبّر مكتبك بثقة» — six rungs whose bottom rule deepens
/// from paper to brand, so the ladder shows growth without a chart.
class GrowthSection extends StatelessWidget {
  const GrowthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface2,
      topBorder: true,
      bottomBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            headline: 'ابدأ منظمًا... وكبّر مكتبك بثقة',
            lead: 'EWT تساعدك تحافظ على السيطرة مع نمو عملياتك.',
            maxWidth: 620,
            headlineMin: 24,
            headlineVw: 3,
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 40)),
          LandingAutoGrid(
            minItemWidth: 150,
            spacing: 10,
            children: [
              for (final rung in LandingContent.growth)
                _GrowthCard(
                  step: rung.step,
                  title: rung.title,
                  bar: rung.bar,
                  brandBorder: rung.brandBorder,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.step,
    required this.title,
    required this.bar,
    required this.brandBorder,
  });

  final String step;
  final String title;
  final Color bar;
  final bool brandBorder;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      radius: 12,
      borderColor: brandBorder
          ? LandingPalette.brandLine
          : LandingPalette.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // The rule sits on the bottom edge so the rules line up across a row
        // whose titles wrap to different heights.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step,
                style: LandingType.label(
                  10.5,
                  color: LandingPalette.brand,
                  weight: FontWeight.w900,
                ).copyWith(letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: LandingType.cardTitle(14).copyWith(height: 1.5),
              ),
              const SizedBox(height: 12),
            ],
          ),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
