import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «ابدأ منظمًا... وكبّر مكتبك بثقة» — six rungs whose bars deepen toward
/// brand as the office grows into them.
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LandingContent.growthHeadline,
                    style: LandingType.heading(
                      landingClamp(context, min: 24, vw: 3, max: 38),
                    ).copyWith(height: 1.32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LandingContent.growthLead,
                    style: LandingType.lead(15.5),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 40)),
          LandingAutoGrid(
            minItemWidth: 150,
            spacing: 10,
            stagger: true,
            children: [
              for (final step in LandingContent.growth) _GrowthCard(step: step),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.step});

  final LandingGrowthStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: step.borderColor),
        boxShadow: LandingPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // `margin-top: auto` on the bar. The cell is measured unbounded first,
        // so the gap is opened by the alignment rather than by a [Spacer].
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.number,
                textDirection: TextDirection.ltr,
                style: LandingType.metric(
                  10.5,
                  color: LandingPalette.brand,
                ).copyWith(letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                step.title,
                style: LandingType.metric(
                  14,
                ).copyWith(letterSpacing: 0, height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: step.barColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
