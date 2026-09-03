import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_device.dart';
import '../widgets/landing_layout.dart';

/// «تطبيق الكابتن» — the driver's phone beside what the office gets from it.
///
/// The band wraps in reverse so the copy leads on a narrow screen: the phone
/// is the evidence, not the argument, and shouldn't be the first thing a
/// reader scrolls past.
class CaptainSection extends StatelessWidget {
  const CaptainSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      topBorder: true,
      bottomBorder: true,
      child: LandingSplit(
        breakpoint: 760,
        gap: landingClamp(context, min: 30, vw: 4, max: 58),
        // 300px phone / 380px copy bases -> ~13:15.
        startFlex: 13,
        endFlex: 15,
        reverseWhenStacked: true,
        start: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: LandingPhoneDuo(
              // The trip the captain is running — stop by stop, with the
              // boarding it records — and his day's assigned trips behind it.
              // Not the map: following a vehicle is the rider's screen, and
              // the captain's tracking is what this one reports upward.
              frontAsset: LandingShots.captainTrip,
              backAsset: LandingShots.captainHome,
              width: 246,
            ),
          ),
        ),
        end: const _CaptainCopy(),
      ),
    );
  }
}

class _CaptainCopy extends StatelessWidget {
  const _CaptainCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingSectionIntro(
          eyebrow: 'تطبيق الكابتن',
          headline: 'الكابتن يعرف مهمته، وأنت تعرف حالة الرحلة',
          lead:
              'كل كابتن يشوف الرحلات المسندة إليه وتفاصيلها، بينما تظل أنت على '
              'اطلاع كامل بحالة التشغيل من لوحة التحكم.',
          maxWidth: 520,
          headlineMin: 24,
          headlineVw: 3,
          headlineMax: 36,
        ),
        const SizedBox(height: 24),
        LandingAutoGrid(
          minItemWidth: 200,
          spacing: 11,
          maxColumns: 2,
          children: [
            for (final benefit in LandingContent.captainBenefits)
              _BenefitTile(point: benefit),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: LandingPalette.brandTint,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: LandingPalette.brandLine),
          ),
          child: Text(
            'خلّي الكابتن ينفذ دوره... وأنت تفضل مسيطر على العملية.',
            style: LandingType.label(
              13.5,
              color: LandingPalette.navy,
              weight: FontWeight.w800,
            ).copyWith(height: 1.7),
          ),
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(14),
      background: LandingPalette.surface2,
      shadow: const [],
      radius: 11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(point.icon, size: 19, color: LandingPalette.brand),
          const SizedBox(height: 8),
          Text(point.title, style: LandingType.cardTitle(13.5)),
          const SizedBox(height: 4),
          Text(
            point.body,
            style: LandingType.cardBody(12.5).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
