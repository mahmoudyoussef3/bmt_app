import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «المميزات» — the six modules an office runs day to day, one card each.
class OperationsSection extends StatelessWidget {
  const OperationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: LandingContent.operationsEyebrow,
            headline: LandingContent.operationsHeadline,
            maxWidth: 620,
          ),
          SizedBox(height: landingClamp(context, min: 28, vw: 3.5, max: 44)),
          LandingAutoGrid(
            minItemWidth: 290,
            spacing: 13,
            stagger: true,
            children: [
              for (final module in LandingContent.operations)
                _OperationCard(point: module),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingHoverCard(
      lift: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandingIconSquare(icon: point.icon),
          const SizedBox(height: 15),
          Text(point.title, style: LandingType.cardTitle(16.5)),
          const SizedBox(height: 7),
          Text(point.body, style: LandingType.cardBody(13.5)),
        ],
      ),
    );
  }
}
