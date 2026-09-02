import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «إدارة العمليات» — the six modules an office runs day to day.
class OperationsSection extends StatelessWidget {
  const OperationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'إدارة العمليات',
            headline: 'شغّل مكتبك بشكل أكثر تنظيمًا',
            maxWidth: 620,
          ),
          SizedBox(height: landingClamp(context, min: 28, vw: 3.5, max: 44)),
          LandingAutoGrid(
            minItemWidth: 290,
            spacing: 13,
            children: [
              for (final item in LandingContent.operations)
                _OperationCard(point: item),
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
        mainAxisSize: MainAxisSize.min,
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
