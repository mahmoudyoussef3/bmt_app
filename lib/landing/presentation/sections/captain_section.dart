import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_frames.dart';
import '../widgets/landing_layout.dart';

/// «تطبيق الكابتن» — the driver's screen beside what it buys the office.
class CaptainSection extends StatelessWidget {
  const CaptainSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      topBorder: true,
      bottomBorder: true,
      child: LandingSplit(
        breakpoint: 720,
        gap: landingClamp(context, min: 30, vw: 4, max: 58),
        startFlex: 300,
        endFlex: 380,
        // `flex-wrap: wrap-reverse` — when the band collapses the copy leads
        // and the phone follows it, rather than the reader meeting a screen
        // before they have been told what it is.
        reverseWhenStacked: true,
        start: const Center(
          child: LandingPhoneShell(
            designWidth: 290,
            bodyPadding: 10,
            outerRadius: 36,
            innerRadius: 28,
            screenColor: LandingPalette.surface2,
            shadow: [
              BoxShadow(
                color: Color(0x8C0B1B34),
                offset: Offset(0, 38),
                blurRadius: 74,
                spreadRadius: -34,
              ),
            ],
            // The captain's own day: the trip under way, the count boarded,
            // and the rest of today's assignments under it.
            child: LandingShotScreen(asset: LandingShots.captainHome),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LandingSectionIntro(
          eyebrow: LandingContent.captainEyebrow,
          headline: LandingContent.captainHeadline,
          lead: LandingContent.captainLead,
          maxWidth: 520,
          headlineMin: 24,
          headlineVw: 3,
          headlineMax: 36,
        ),
        const SizedBox(height: 24),
        LandingAutoGrid(
          minItemWidth: 200,
          spacing: 11,
          stagger: true,
          children: [
            for (final benefit in LandingContent.captainBenefits)
              _BenefitCard(point: benefit),
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
            LandingContent.captainClosing,
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

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(14),
      background: LandingPalette.surface2,
      radius: 11,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(point.icon, size: 19, color: LandingPalette.brand),
          const SizedBox(height: 8),
          Text(
            point.title,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
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
