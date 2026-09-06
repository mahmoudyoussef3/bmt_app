import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_frames.dart';
import '../widgets/landing_layout.dart';
import '../widgets/landing_motion.dart';

/// The fold: the promise, the two calls to action, and the three surfaces an
/// office actually runs on — the captain's phone, the console, the rider's
/// phone — standing bottom-aligned in a row.
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        // `linear-gradient(180deg, #FFFFFF, var(--page))` — straight down, so
        // the stops read the same in either direction.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, LandingPalette.page],
        ),
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _HeroGlow())),
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
                  _HeroCopy(
                    onGetStarted: onGetStarted,
                    onSeeDashboard: onSeeDashboard,
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 34, vw: 4, max: 54),
                  ),
                  const LandingReveal(
                    rise: 26,
                    delay: Duration(milliseconds: 280),
                    child: _HeroRig(),
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 24, vw: 3, max: 34),
                  ),
                  const LandingReveal(
                    delay: Duration(milliseconds: 380),
                    child: _HeroTrustBar(),
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

/// The two soft washes behind the fold. Both are stated as physical CSS
/// percentages of the section box, so they are painted rather than expressed
/// as directional alignments: `at 85% -12%` means 85% from the left edge in
/// an RTL page too.
class _HeroGlow extends CustomPainter {
  const _HeroGlow();

  @override
  void paint(Canvas canvas, Size size) {
    void wash(Offset centre, Size radii, Color color) {
      final rect = Rect.fromCenter(
        center: centre,
        width: radii.width * 2,
        height: radii.height * 2,
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ).createShader(rect),
      );
    }

    wash(
      Offset(size.width * 0.85, size.height * -0.12),
      const Size(900, 440),
      LandingPalette.brand.withValues(alpha: 0.11),
    );
    wash(
      Offset(0, size.height * 1.05),
      const Size(700, 360),
      LandingPalette.navy.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(_HeroGlow oldDelegate) => false;
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onGetStarted, required this.onSeeDashboard});

  final VoidCallback onGetStarted;
  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    final headlineSize = landingClamp(context, min: 30, vw: 4.6, max: 56);
    final bodySize = landingClamp(context, min: 15, vw: 1.4, max: 18.5);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LandingReveal(rise: 12, child: _HeroBadge()),
            const SizedBox(height: 20),
            LandingReveal(
              rise: 16,
              delay: const Duration(milliseconds: 70),
              child: Text.rich(
                TextSpan(
                  text: LandingContent.heroHeadline,
                  children: const [
                    TextSpan(
                      text: LandingContent.heroHeadlineAccent,
                      style: TextStyle(color: LandingPalette.brand),
                    ),
                  ],
                ),
                style: LandingType.display(headlineSize),
              ),
            ),
            const SizedBox(height: 20),
            LandingReveal(
              rise: 16,
              delay: const Duration(milliseconds: 140),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Text(
                  LandingContent.heroBody,
                  style: LandingType.lead(bodySize).copyWith(height: 1.85),
                ),
              ),
            ),
            const SizedBox(height: 28),
            LandingReveal(
              rise: 16,
              delay: const Duration(milliseconds: 210),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  LandingButton(
                    label: LandingContent.heroPrimaryCta,
                    onPressed: onGetStarted,
                    // `arrow_back` in the design is the *physical* left arrow,
                    // which in an RTL page is the forward direction. Flutter's
                    // arrows mirror with the text direction, so the forward one
                    // is the icon that resolves to it.
                    icon: Icons.arrow_forward_rounded,
                  ),
                  LandingButton(
                    label: LandingContent.heroSecondaryCta,
                    onPressed: onSeeDashboard,
                    style: LandingButtonStyle.secondary,
                    leadingIcon: Icons.play_circle_outline_rounded,
                    leadingIconColor: LandingPalette.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LandingType.label(
                12,
                color: LandingPalette.brandInk,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Captain phone · console · rider phone, bottom-aligned.
///
/// The CSS bases are 208 / 560 / 208 with minimums of 186 / 300 / 186, so the
/// row holds together down to roughly 720px of content width and stacks below
/// that rather than squeezing the console to nothing.
class _HeroRig extends StatelessWidget {
  const _HeroRig();

  static const _phoneWidth = 208.0;
  static const _phoneMin = 186.0;
  static const _consoleMin = 300.0;

  @override
  Widget build(BuildContext context) {
    final gap = landingClamp(context, min: 14, vw: 1.8, max: 24);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fits = width >= _phoneMin * 2 + _consoleMin + gap * 2;
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CaptainPhoneColumn(),
              SizedBox(height: gap + 8),
              const _ConsoleColumn(),
              SizedBox(height: gap + 8),
              const _RiderPhoneColumn(),
            ],
          );
        }
        // `flex: 0 1 208px` — the phones hold 208 and only give ground when
        // the console has been squeezed to its own minimum.
        final phone = ((width - _consoleMin - gap * 2) / 2).clamp(
          _phoneMin,
          _phoneWidth,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: phone, child: const _CaptainPhoneColumn()),
            SizedBox(width: gap),
            const Expanded(child: _ConsoleColumn()),
            SizedBox(width: gap),
            SizedBox(width: phone, child: const _RiderPhoneColumn()),
          ],
        );
      },
    );
  }
}

/// A mockup with the label that says which app it is.
class _RigColumn extends StatelessWidget {
  const _RigColumn({
    required this.child,
    required this.icon,
    required this.caption,
  });

  final Widget child;
  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: LandingPalette.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LandingType.label(
                  12.5,
                  color: LandingPalette.ink,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Phones ──────────────────────────────────────────────────────────────────
//
// Both are real captures of the shipping apps: the captain's screen mid-trip
// and the rider's home. The console between them is drawn — see the note on
// [LandingShots] — but nothing in the fold states a figure a shot beside it
// contradicts, so the two sit together honestly.

class _CaptainPhoneColumn extends StatelessWidget {
  const _CaptainPhoneColumn();

  @override
  Widget build(BuildContext context) {
    return const _RigColumn(
      icon: Icons.badge_rounded,
      caption: LandingContent.heroCaptainCaption,
      child: LandingPhoneShell(
        designWidth: 208,
        child: LandingShotScreen(asset: LandingShots.captainTrip),
      ),
    );
  }
}

class _RiderPhoneColumn extends StatelessWidget {
  const _RiderPhoneColumn();

  @override
  Widget build(BuildContext context) {
    return const _RigColumn(
      icon: Icons.smartphone_rounded,
      caption: LandingContent.heroRiderCaption,
      child: LandingPhoneShell(
        designWidth: 208,
        child: LandingShotScreen(asset: LandingShots.clientHome),
      ),
    );
  }
}

// ── Console ─────────────────────────────────────────────────────────────────

class _ConsoleColumn extends StatelessWidget {
  const _ConsoleColumn();

  @override
  Widget build(BuildContext context) {
    return const _RigColumn(
      icon: Icons.dashboard_rounded,
      caption: LandingContent.heroConsoleCaption,
      child: LandingBrowserShell(
        url: LandingContent.heroConsoleUrl,
        child: _ConsoleBody(),
      ),
    );
  }
}

class _ConsoleBody extends StatelessWidget {
  const _ConsoleBody();

  @override
  Widget build(BuildContext context) {
    final pad = landingClamp(context, min: 14, vw: 2, max: 20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ConsoleAppBar(),
        Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ConsoleToolbar(),
              const SizedBox(height: 14),
              LandingAutoGrid(
                minItemWidth: 150,
                spacing: 11,
                children: [
                  for (final kpi in LandingContent.heroKpis)
                    _HeroKpiTile(kpi: kpi),
                ],
              ),
              const SizedBox(height: 12),
              const LandingStretchRow(
                breakpoint: 612,
                flex: [1, 1],
                children: [_HeroChartCard(), _HeroTripsCard()],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsoleAppBar extends StatelessWidget {
  const _ConsoleAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: LandingPalette.navy,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The design gives the title an automatic width and pushes the
          // stamp away with an empty `flex:1` spacer. Making all three of
          // them flexible instead split the bar into equal thirds and clipped
          // the office name with 200px to spare, so the title's group takes
          // the larger share and the stamp only ever takes what it needs.
          Flexible(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.space_dashboard_rounded,
                  size: 18,
                  color: LandingPalette.onNavyAccent,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    LandingContent.heroConsoleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LandingType.label(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LandingLiveDot(),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      LandingContent.heroConsoleStamp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingType.label(
                        11,
                        color: Colors.white.withValues(alpha: 0.65),
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

class _ConsoleToolbar extends StatelessWidget {
  const _ConsoleToolbar();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Text(
          LandingContent.heroConsoleOverview,
          style: LandingType.metric(15).copyWith(letterSpacing: 0),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < LandingContent.heroConsoleRanges.length; i++)
              LandingPill(
                label: LandingContent.heroConsoleRanges[i],
                selected: i == 0,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroKpiTile extends StatelessWidget {
  const _HeroKpiTile({required this.kpi});

  final LandingKpi kpi;

  @override
  Widget build(BuildContext context) {
    final valueSize = landingClamp(context, min: 22, vw: 2.4, max: 28);
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      background: LandingPalette.surface2,
      radius: 12,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(kpi.icon, size: 17, color: LandingPalette.brand),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.label(11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: LandingLatin(
                  kpi.value,
                  style: LandingType.metric(valueSize),
                ),
              ),
              if (kpi.unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(kpi.unit, style: LandingType.label(11)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            landingIsolateFigures(kpi.delta),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              11,
              color: kpi.deltaColor,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChartCard extends StatelessWidget {
  const _HeroChartCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      radius: 12,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LandingContent.heroChartTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.metric(13).copyWith(letterSpacing: 0),
                ),
              ),
              const SizedBox(width: 8),
              Text(LandingContent.heroChartNote, style: LandingType.label(11)),
            ],
          ),
          const SizedBox(height: 12),
          const LandingBarChart(
            heights: LandingContent.heroChartHeights,
            labels: LandingContent.heroChartLabels,
          ),
        ],
      ),
    );
  }
}

class _HeroTripsCard extends StatelessWidget {
  const _HeroTripsCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: EdgeInsets.zero,
      radius: 12,
      shadow: const [],
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: const BoxDecoration(
              color: LandingPalette.raised,
              border: Border(bottom: BorderSide(color: LandingPalette.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    LandingContent.heroTripsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LandingType.metric(12.5).copyWith(letterSpacing: 0),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  LandingContent.heroTripsAction,
                  style: LandingType.label(
                    11,
                    color: LandingPalette.brandInk,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (final trip in LandingContent.heroTrips) _HeroTripRow(trip: trip),
        ],
      ),
    );
  }
}

class _HeroTripRow extends StatelessWidget {
  const _HeroTripRow({required this.trip});

  final LandingTrip trip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _row(constraints.maxWidth - 30),
    );
  }

  Widget _row(double width) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LandingPalette.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The design sets no `white-space` on the route, so a long
                // corridor wraps rather than being cut — the trailing cells
                // are the ones pinned to one line.
                Text(
                  trip.route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.label(
                    13,
                    color: LandingPalette.ink,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trip.time} · ${trip.captain}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.label(11, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: LandingLatin(
              trip.seats,
              style: LandingType.label(
                12,
                color: LandingPalette.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: LandingBadge(label: trip.status, tone: trip.tone),
          ),
        ],
      ),
    );
  }
}

// ── Trust bar ───────────────────────────────────────────────────────────────

class _HeroTrustBar extends StatelessWidget {
  const _HeroTrustBar();

  @override
  Widget build(BuildContext context) {
    final pad = landingClamp(context, min: 16, vw: 1.8, max: 22);
    return LandingCard(
      padding: EdgeInsets.zero,
      shadow: const [
        BoxShadow(
          color: Color(0x0A1C1917),
          offset: Offset(0, 2),
          blurRadius: 10,
        ),
      ],
      clip: true,
      child: LandingAutoGrid(
        minItemWidth: 210,
        spacing: 0,
        children: [
          for (final point in LandingContent.heroTrust)
            Container(
              padding: EdgeInsets.all(pad),
              // `border-left` is physical in CSS and stays physical here, so
              // in RTL it falls between cells rather than mirroring away.
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: LandingPalette.borderSoft),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      point.icon,
                      size: 20,
                      color: LandingPalette.brand,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.title,
                          style: LandingType.metric(
                            14.5,
                          ).copyWith(letterSpacing: 0, height: 1.3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          point.body,
                          style: LandingType.label(
                            12.5,
                            weight: FontWeight.w400,
                          ).copyWith(height: 1.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
