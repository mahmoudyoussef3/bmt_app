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
///
/// The band reads claim → evidence → payoff: the intro states it, the four
/// step cards show it, and the closing strip lists everything the rider
/// settles himself. That list used to open the band as a run of chips, where
/// it repeated the four steps *before* the screens that prove them and left
/// an orphan pill on a second row; as a recap underneath it says something
/// the cards do not.
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
          SizedBox(height: landingClamp(context, min: 28, vw: 3.6, max: 48)),
          // Four across or two by two — never three, which would strand the
          // fourth step alone on a row of its own and break the sequence the
          // whole band is built to show.
          LayoutBuilder(
            builder: (context, constraints) => LandingAutoGrid(
              minItemWidth: 120,
              maxColumns: switch (constraints.maxWidth) {
                >= 1040 => 4,
                >= 540 => 2,
                _ => 1,
              },
              spacing: landingClamp(context, min: 14, vw: 1.6, max: 22),
              children: [
                for (final step in LandingContent.clientJourney)
                  _JourneyCard(
                    step: step.step,
                    icon: step.icon,
                    title: step.title,
                    body: step.body,
                    shot: step.shot,
                  ),
              ],
            ),
          ),
          SizedBox(height: landingClamp(context, min: 16, vw: 1.8, max: 24)),
          const _SelfServeStrip(),
        ],
      ),
    );
  }
}

/// One step: its number and label, its caption, and the screen it happens on.
///
/// The label leads and the capture follows, which is the order the reader
/// needs — a row of four phones with the numbers underneath asks them to look
/// first and find out afterwards what they were looking at.
class _JourneyCard extends StatefulWidget {
  const _JourneyCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.body,
    required this.shot,
  });

  final String step;
  final IconData icon;
  final String title;
  final String body;
  final String shot;

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // The border tint on hover, not the lift: these cards are read, not
    // clicked, and a card that rises under the pointer promises a click the
    // section has nothing to give. It is the same warm-the-border response
    // the rest of the page's card grids use.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: LandingPalette.surface,
          borderRadius: LandingRadii.cardR,
          border: Border.all(
            color: _hovered ? LandingPalette.brandLine : LandingPalette.border,
          ),
          boxShadow: LandingPalette.cardShadow,
        ),
        // The grid stretches every cell in a run to the tallest, and the extra
        // height is spent on the gap between the caption and the well — so a
        // two-line caption never pushes its phone below its neighbours'.
        //
        // `spaceBetween` rather than a [Spacer]: the run hands its cells a
        // minimum height with the maximum still unbounded, and a flex child
        // under an unbounded main axis is an error.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Number, rule, icon — the same header the «كيف تعمل EWT؟»
                  // step cards wear. Four of them side by side put the four
                  // numbers on one line, which is the sequence the row claims.
                  Row(
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: LandingPalette.brandTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: LandingPalette.brandLine),
                        ),
                        child: Text(
                          widget.step,
                          style: LandingType.label(
                            12,
                            color: LandingPalette.brandInk,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: SizedBox(
                          height: 1,
                          child: ColoredBox(color: LandingPalette.border),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(widget.icon, size: 18, color: LandingPalette.faint),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(widget.title, style: LandingType.cardTitle(15)),
                  const SizedBox(height: 6),
                  Text(
                    widget.body,
                    style: LandingType.cardBody(12.5).copyWith(height: 1.75),
                  ),
                ],
              ),
            ),
            _ShotWell(shot: widget.shot),
          ],
        ),
      ),
    );
  }
}

/// The recessed ground the capture sits on.
///
/// The phone used to stand on the section itself, which left it and its
/// caption two loose objects a reader had to associate. Sitting it in a
/// tinted well inside the card makes the pair one unit, and the four wells
/// give the row a common floor line.
class _ShotWell extends StatelessWidget {
  const _ShotWell({required this.shot});

  final String shot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LandingPalette.surface2,
        border: Border(top: BorderSide(color: LandingPalette.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          // The capture goes in whole. Trimming its bottom edge did keep the
          // row short, but it also squared the device off: a phone that is
          // not noticeably taller than it is wide reads as a small tablet,
          // and the screens inside these four are the product.
          child: LandingPhoneShot(
            asset: shot,
            // The cap only binds on the two- and one-column layouts, where
            // the card is far wider than a phone; at four across the well is
            // narrower than this and the shot simply fills it.
            width: constraints.maxWidth.clamp(0.0, 300.0),
            shadow: false,
          ),
        ),
      ),
    );
  }
}

/// The payoff: everything above, restated as the list of calls the office no
/// longer takes.
class _SelfServeStrip extends StatelessWidget {
  const _SelfServeStrip();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      background: LandingPalette.surface2,
      shadow: const [],
      child: LandingSplit(
        breakpoint: 860,
        // 300px claim / 520px list bases.
        startFlex: 3,
        endFlex: 5,
        gap: 22,
        crossAxisAlignment: CrossAxisAlignment.start,
        start: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LandingIconSquare(
              icon: Icons.phone_disabled_rounded,
              size: 38,
              iconSize: 19,
              radius: 11,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'كل ده بيعمله العميل بنفسه، من غير مكالمة لمكتبك',
                  style: LandingType.cardTitle(15).copyWith(height: 1.6),
                ),
              ),
            ),
          ],
        ),
        end: LandingAutoGrid(
          minItemWidth: 230,
          spacing: 10,
          maxColumns: 2,
          stretch: false,
          children: [
            for (final point in LandingContent.clientPoints)
              _SelfServePoint(label: point),
          ],
        ),
      ),
    );
  }
}

class _SelfServePoint extends StatelessWidget {
  const _SelfServePoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: LandingPalette.brand,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: LandingType.label(
              12.5,
              color: LandingPalette.ink,
              weight: FontWeight.w600,
            ).copyWith(height: 1.7),
          ),
        ),
      ],
    );
  }
}
