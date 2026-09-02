import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_device.dart';
import '../widgets/landing_layout.dart';

/// The opening band: the pitch, two CTAs, the three-device product rig and
/// the four trust lines beneath it.
///
/// The rig is the section's real argument. The copy claims an office runs
/// from one console while its riders and captains carry the rest, so the band
/// shows exactly that — the real console, the real rider app and the real
/// captain app, photographed by `tool/showcase`, not drawn to look like them.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onSeeDashboard,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    final headline = landingClamp(context, min: 30, vw: 4.6, max: 56);
    final body = landingClamp(context, min: 15, vw: 1.4, max: 18.5);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LandingPalette.surface, LandingPalette.page],
        ),
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Stack(
        children: [
          // Two soft washes — brand at the top outer corner, navy at the
          // bottom inner one — that keep the white-to-paper fade from
          // reading as a flat band.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7, -1.24),
                  radius: 1.1,
                  colors: [Color(0x1C2563EB), Color(0x002563EB)],
                  stops: [0, 0.7],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1, 1.1),
                  radius: 0.9,
                  colors: [Color(0x0F0B1B34), Color(0x000B1B34)],
                  stops: [0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: landingClamp(context, min: 44, vw: 5.5, max: 80),
              bottom: landingClamp(context, min: 46, vw: 5.5, max: 72),
            ),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _HeroBadge(),
                        const SizedBox(height: 20),
                        Text.rich(
                          TextSpan(
                            text: LandingContent.heroHeadlineLead,
                            children: const [
                              TextSpan(
                                text: LandingContent.heroHeadlineAccent,
                                style: TextStyle(color: LandingPalette.brand),
                              ),
                            ],
                          ),
                          style: LandingType.display(headline),
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 660),
                          child: Text(
                            LandingContent.heroBody,
                            style: LandingType.lead(body),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            LandingButton(
                              label: LandingContent.heroPrimaryCta,
                              icon: Icons.arrow_back_rounded,
                              onPressed: onGetStarted,
                            ),
                            LandingButton(
                              label: LandingContent.heroSecondaryCta,
                              icon: Icons.play_circle_outline_rounded,
                              style: LandingButtonStyle.secondary,
                              onPressed: onSeeDashboard,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 34, vw: 4, max: 54),
                  ),
                  const _HeroShowcase(),
                  SizedBox(
                    height: landingClamp(context, min: 24, vw: 3, max: 34),
                  ),
                  LandingAutoGrid(
                    minItemWidth: 200,
                    spacing: landingClamp(context, min: 14, vw: 2, max: 26),
                    children: [
                      for (final item in LandingContent.heroTrust)
                        _TrustLine(point: item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LandingPalette.brandTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LandingPalette.brandLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 15,
            color: LandingPalette.brandInk,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              LandingContent.heroBadge,
              style: LandingType.label(
                12,
                color: LandingPalette.brandInk,
                weight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(point.icon, size: 21, color: LandingPalette.brand),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(point.title, style: LandingType.cardTitle(14.5)),
              const SizedBox(height: 3),
              Text(
                point.body,
                style: LandingType.cardBody(12.5).copyWith(height: 1.7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The three-device product rig.
///
/// Wide, the console sits centred with a phone tucked under each shoulder —
/// the phones are inset from the page edges by the same amount the console is
/// inset from them, so the group reads as one object rather than three. Below
/// that width there is no room to overlap anything, so the console takes the
/// full column and the two phones line up beneath it.
class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 940) return _HeroRig(width: width);
        // Two phones and the gap between them, never wider than the column
        // and never so small the screen inside stops being readable.
        final phone = ((width - 16) / 2).clamp(112.0, 186.0);
        return _HeroStack(phoneWidth: phone);
      },
    );
  }
}

class _HeroRig extends StatelessWidget {
  const _HeroRig({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final phone = (width * 0.165).clamp(160.0, 215.0);
    // How far the console is held off each edge — a little under the phone's
    // width, so each phone overlaps the console rather than sitting beside it.
    final inset = phone * 0.62;

    return Stack(
      // The phones hang below the console's bottom edge; a Stack clips at its
      // own bounds by default and would cut them off.
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: inset,
            right: inset,
            bottom: phone * 0.30,
          ),
          child: const LandingBrowserShot(
            asset: LandingShots.consoleOverview,
            crop: 0.14,
          ),
        ),
        PositionedDirectional(
          start: 0,
          bottom: 0,
          child: LandingPhoneShot(
            asset: LandingShots.captainMap,
            width: phone,
            tilt: -0.035,
          ),
        ),
        PositionedDirectional(
          end: 0,
          bottom: 0,
          child: LandingPhoneShot(
            asset: LandingShots.clientHome,
            width: phone,
            tilt: 0.035,
          ),
        ),
      ],
    );
  }
}

class _HeroStack extends StatelessWidget {
  const _HeroStack({required this.phoneWidth});

  final double phoneWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LandingBrowserShot(
          asset: LandingShots.consoleOverview,
          crop: 0.1,
        ),
        SizedBox(height: phoneWidth * 0.12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LandingPhoneShot(asset: LandingShots.captainMap, width: phoneWidth),
            const SizedBox(width: 16),
            LandingPhoneShot(asset: LandingShots.clientHome, width: phoneWidth),
          ],
        ),
      ],
    );
  }
}
