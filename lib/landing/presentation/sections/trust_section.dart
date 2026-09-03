import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// The closing credibility band: the claim on one side, the seven concrete
/// capabilities backing it on the other.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: LandingSplit(
        breakpoint: 720,
        gap: landingClamp(context, min: 26, vw: 4, max: 48),
        // 320px / 380px bases -> ~9:10.
        startFlex: 9,
        endFlex: 10,
        start: const LandingSectionIntro(
          eyebrow: 'الأساس',
          headline: 'نظام مصمم حول طبيعة عمل مكاتب النقل',
          lead:
              'مبني على الخطوات الفعلية لتشغيل مكتب النقل: من إنشاء الرحلة، '
              'لإسناد الكابتن، للحجز، للدفع، للتقرير.',
          maxWidth: 480,
          headlineMin: 23,
          headlineVw: 2.8,
          headlineMax: 34,
        ),
        end: LandingAutoGrid(
          minItemWidth: 190,
          spacing: 10,
          children: [
            for (final item in LandingContent.trustItems)
              _TrustTile(icon: item.icon, title: item.title),
          ],
        ),
      ),
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(13),
      radius: 10,
      child: Row(
        children: [
          Icon(icon, size: 19, color: LandingPalette.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: LandingType.label(13, color: LandingPalette.ink),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
