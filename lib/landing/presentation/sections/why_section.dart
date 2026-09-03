import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «ليه أصحاب مكاتب النقل يختاروا EWT؟» — the six reasons.
class WhySection extends StatelessWidget {
  const WhySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'الأسباب',
            headline: 'ليه أصحاب مكاتب النقل يختاروا EWT؟',
            maxWidth: 720,
            headlineMin: 24,
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          LandingAutoGrid(
            minItemWidth: 280,
            spacing: 13,
            children: [
              for (final reason in LandingContent.why) _WhyCard(point: reason),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingHoverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(point.icon, size: 20, color: LandingPalette.brand),
              const SizedBox(width: 9),
              Expanded(
                child: Text(point.title, style: LandingType.cardTitle(16)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(point.body, style: LandingType.cardBody(13.5)),
        ],
      ),
    );
  }
}
