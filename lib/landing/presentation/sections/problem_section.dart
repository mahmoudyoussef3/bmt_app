import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «التحدي» — the four symptoms of running an office by hand, closed by the
/// one-line claim that answers them.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key, required this.onSeeDashboard});

  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: LandingContent.problemEyebrow,
            eyebrowColor: LandingPalette.warn,
            headline: LandingContent.problemHeadline,
            lead: LandingContent.problemLead,
          ),
          SizedBox(height: landingClamp(context, min: 28, vw: 3.5, max: 44)),
          LandingAutoGrid(
            minItemWidth: 240,
            spacing: 13,
            stagger: true,
            children: [
              for (final problem in LandingContent.problems)
                _ProblemCard(point: problem),
            ],
          ),
          SizedBox(height: landingClamp(context, min: 24, vw: 3, max: 36)),
          _ProblemBanner(onSeeDashboard: onSeeDashboard),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      background: LandingPalette.surface2,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(point.icon, size: 22, color: LandingPalette.warn),
          const SizedBox(height: 12),
          Text(point.title, style: LandingType.cardTitle(16)),
          const SizedBox(height: 6),
          Text(point.body, style: LandingType.cardBody(13.5)),
        ],
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.onSeeDashboard});

  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    final size = landingClamp(context, min: 17, vw: 2, max: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: LandingPalette.brandTint,
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: LandingPalette.brandLine),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icon = const Icon(
            Icons.merge_rounded,
            size: 26,
            color: LandingPalette.brandInk,
          );
          final claim = Text(
            LandingContent.problemBannerText,
            style: LandingType.metric(
              size,
              color: LandingPalette.navy,
            ).copyWith(letterSpacing: -0.4),
          );
          final button = LandingButton(
            label: LandingContent.problemBannerCta,
            onPressed: onSeeDashboard,
            style: LandingButtonStyle.navy,
            icon: Icons.arrow_forward_rounded,
            height: 44,
          );
          // `flex: 1 1 240px` on the claim: it keeps the row together until
          // the icon, 240px of copy and the button stop fitting.
          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(child: claim),
                const SizedBox(width: 14),
                button,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 14),
                  Expanded(child: claim),
                ],
              ),
              const SizedBox(height: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}
