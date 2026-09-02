import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_device.dart';
import '../widgets/landing_layout.dart';

/// «تجربة العميل» — what the rider can do alone, told as the four screens he
/// actually passes through.
///
/// The band used to be copy beside one drawn phone. The claim it makes is
/// about a *sequence* — search, seat, trip, payment — and a single mock could
/// only assert that; four real captures in order show it, and each one is a
/// screen the office no longer has to answer the phone for.
class ClientSection extends StatelessWidget {
  const ClientSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      topBorder: true,
      bottomBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'تجربة العميل',
            headline: 'قدّم لعملائك تجربة أفضل، بدون ما تزود الحمل على فريقك',
            lead: 'كل ما العميل يقدر يعمله بنفسه، يقلل الضغط على مكتبك وفريقك.',
            align: TextAlign.center,
            center: true,
            maxWidth: 640,
            headlineMin: 23,
            headlineVw: 2.8,
            headlineMax: 36,
          ),
          const SizedBox(height: 18),
          const _ClientPoints(),
          SizedBox(height: landingClamp(context, min: 30, vw: 4, max: 50)),
          LandingAutoGrid(
            // Four across on a desktop, two on a tablet, one on a phone —
            // and the steps stay in order at every one of those widths.
            minItemWidth: 190,
            spacing: landingClamp(context, min: 14, vw: 2, max: 26),
            children: [
              for (final step in LandingContent.clientJourney)
                _JourneyStep(
                  step: step.step,
                  title: step.title,
                  body: step.body,
                  shot: step.shot,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The five things the rider handles himself, as a centred run of chips.
class _ClientPoints extends StatelessWidget {
  const _ClientPoints();

  @override
  Widget build(BuildContext context) {
    // A Wrap lays its children out unconstrained along the main axis, so a
    // chip whose label is longer than the column runs off the edge rather
    // than wrapping. Each one is capped at the row's own width instead.
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final point in LandingContent.clientPoints)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: LandingPalette.surface2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LandingPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: LandingPalette.brand,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        point,
                        style: LandingType.label(
                          12.5,
                          color: LandingPalette.ink,
                          weight: FontWeight.w600,
                        ),
                      ),
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

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.step,
    required this.title,
    required this.body,
    required this.shot,
  });

  final String step;
  final String title;
  final String body;
  final String shot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // The grid measures a row by real layout and pins the tallest as a
      // minimum, so a cell has no bounded height to hand a Spacer.
      mainAxisSize: MainAxisSize.min,
      children: [
        // The phone takes whatever width the column ended up with, so all
        // four match without any of them being told a number — capped, so a
        // one-column layout does not hand a single phone the whole viewport.
        //
        // The capture goes in whole. Trimming its bottom edge did keep the row
        // short, but it also squared the device off: a phone that is not
        // noticeably taller than it is wide reads as a small tablet, and the
        // screens inside these four are the product.
        LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: LandingPhoneShot(
              asset: shot,
              width: constraints.maxWidth.clamp(0.0, 300.0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LandingPalette.brandTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LandingPalette.brandLine),
              ),
              child: Text(
                step,
                style: LandingType.label(
                  12,
                  color: LandingPalette.brandInk,
                  weight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(title, style: LandingType.cardTitle(14.5))),
          ],
        ),
        const SizedBox(height: 7),
        Text(body, style: LandingType.cardBody(12.5).copyWith(height: 1.75)),
      ],
    );
  }
}
