import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «نظام مصمم حول طبيعة عمل مكاتب النقل» — the claim, and the seven
/// capabilities that back it.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: LandingSplit(
        breakpoint: 740,
        gap: landingClamp(context, min: 26, vw: 4, max: 48),
        startFlex: 32,
        endFlex: 38,
        start: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LandingContent.trustHeadline,
              style: LandingType.heading(
                landingClamp(context, min: 23, vw: 2.8, max: 34),
              ).copyWith(height: 1.35, letterSpacing: -0.7),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                LandingContent.trustLead,
                style: LandingType.lead(15.5),
              ),
            ),
          ],
        ),
        end: LandingAutoGrid(
          minItemWidth: 190,
          spacing: 10,
          stagger: true,
          children: [
            for (final item in LandingContent.trustItems)
              _TrustTile(point: item),
          ],
        ),
      ),
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LandingPalette.border),
        boxShadow: LandingPalette.cardShadow,
      ),
      child: Row(
        children: [
          Icon(point.icon, size: 19, color: LandingPalette.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.title,
              style: LandingType.label(
                13,
                color: LandingPalette.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
