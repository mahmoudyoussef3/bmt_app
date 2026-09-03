import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_device.dart';
import '../widgets/landing_hero_board.dart';
import '../widgets/landing_layout.dart';

/// The opening band: the pitch, two CTAs, the three-device product rig, the
/// key that names the three screens and the four trust lines beneath them.
///
/// The band is built on one axis. Everything above the rig is centred on the
/// page's own centre line — the same centre the rig is composed around — so
/// the fold reads as a single column rather than a paragraph pinned to one
/// margin with a full-width picture under it. That was the old shape, and on
/// a desktop screen it left half the fold empty while pushing the product
/// itself below it.
///
/// The rig is the section's real argument. The copy claims an office runs
/// from one console while its riders and captains carry the rest, so the band
/// shows exactly that: the console with a phone standing either side of it,
/// all three on one floor line.
///
/// The three screens inside it are the page's one exception to the rule that
/// product UI is photographed rather than drawn — see `landing_hero_board.dart`
/// for why the fold trades the capture for something legible at a third of a
/// screen's width. Every band below it is still a real capture.
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
    final headline = landingClamp(context, min: 30, vw: 4.4, max: 54);
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
            // Tighter than the page's section rhythm, top and bottom: the
            // hero's job is to get the product rig onto the first screen, and
            // every pixel spent above the headline is one the console loses.
            padding: EdgeInsets.only(
              top: landingClamp(context, min: 36, vw: 4.2, max: 60),
              bottom: landingClamp(context, min: 44, vw: 5, max: 68),
            ),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _HeroBadge()),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Text.rich(
                        TextSpan(
                          // The break is placed rather than left to the line
                          // breaker: the headline is two clauses and it wants
                          // to fold at the comma between them. Left free it
                          // folds wherever the measured width runs out, which
                          // on a desktop screen strands the last word of the
                          // accent on a line of its own.
                          text:
                              '${LandingContent.heroHeadlineLead.trimRight()}\n',
                          children: const [
                            TextSpan(
                              text: LandingContent.heroHeadlineAccent,
                              style: TextStyle(color: LandingPalette.brand),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: LandingType.display(headline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Text(
                        LandingContent.heroBody,
                        textAlign: TextAlign.center,
                        style: LandingType.lead(body),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _HeroActions(
                    onGetStarted: onGetStarted,
                    onSeeDashboard: onSeeDashboard,
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 30, vw: 3.4, max: 44),
                  ),
                  const _HeroShowcase(),
                  SizedBox(
                    height: landingClamp(context, min: 28, vw: 3.2, max: 40),
                  ),
                  const _HeroTrustBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two calls to action.
///
/// Side by side they are sized to their labels; stacked they are not. Two
/// centred buttons of different widths on a phone read as a mistake, and the
/// wider of the two is the primary — so on a narrow screen both take the full
/// column and the pair becomes a ladder with one obvious first rung.
class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.onGetStarted,
    required this.onSeeDashboard,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final primary = LandingButton(
          label: LandingContent.heroPrimaryCta,
          icon: Icons.arrow_back_rounded,
          expand: stacked,
          onPressed: onGetStarted,
        );
        // Not a play glyph: the button scrolls to the console tour further
        // down the page, and an icon that promises a video the page does not
        // have is a promise broken on the first click.
        final secondary = LandingButton(
          label: LandingContent.heroSecondaryCta,
          icon: Icons.desktop_windows_rounded,
          style: LandingButtonStyle.secondary,
          expand: stacked,
          onPressed: onSeeDashboard,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [primary, const SizedBox(height: 12), secondary],
          );
        }
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [primary, secondary],
        );
      },
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

/// The caption under the rig — which of the three screens is which.
///
/// Three product shots with no names on them ask the reader to guess, and the
/// two phones are the guess nobody gets right. Beside the rig the labels sit
/// directly under the device each one names: the phone columns are the same
/// width the rig gives its phones, so the console's label lands on the same
/// centre line as the console. Stacked, there is nothing to line up against
/// and they run as one centred row.
class _HeroSurfaceKey extends StatelessWidget {
  const _HeroSurfaceKey.spread({required double phoneWidth})
    : _phoneWidth = phoneWidth;
  const _HeroSurfaceKey.centred() : _phoneWidth = null;

  final double? _phoneWidth;

  @override
  Widget build(BuildContext context) {
    final surfaces = LandingContent.heroSurfaces;
    final phone = _phoneWidth;
    if (phone == null) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 22,
        runSpacing: 10,
        children: [for (final surface in surfaces) _KeyItem(surface: surface)],
      );
    }
    // The same columns the rig itself is built from — phone, gap, console,
    // gap, phone — so each label lands on the centre line of the device it
    // names. Start → end in RTL is right → left, which is the order the rig
    // places them in: captain phone, console, rider phone.
    final gap = _rigGap(phone);
    return Row(
      children: [
        SizedBox(
          width: phone,
          child: Center(child: _KeyItem(surface: surfaces[0])),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Center(child: _KeyItem(surface: surfaces[1])),
        ),
        SizedBox(width: gap),
        SizedBox(
          width: phone,
          child: Center(child: _KeyItem(surface: surfaces[2])),
        ),
      ],
    );
  }
}

class _KeyItem extends StatelessWidget {
  const _KeyItem({required this.surface});

  final LandingPoint surface;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(surface.icon, size: 15, color: LandingPalette.faint),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            surface.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(
              12.5,
              color: LandingPalette.muted,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// The four trust lines, gathered into one bordered strip.
///
/// Loose in the page they read as a stray footnote under the phones; inside a
/// single card with rules between them they close the band and give the fold
/// a bottom edge. Columns follow the width — four across, then two, then one
/// — and the rules follow the columns.
class _HeroTrustBar extends StatelessWidget {
  const _HeroTrustBar();

  static const _points = LandingContent.heroTrust;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 4
            : width >= 540
            ? 2
            : 1;

        final rows = <Widget>[];
        for (var i = 0; i < _points.length; i += columns) {
          final slice = _points.sublist(
            i,
            (i + columns).clamp(0, _points.length),
          );
          if (rows.isNotEmpty) rows.add(const _TrustRule.horizontal());
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < slice.length; c++) ...[
                  if (c > 0) const _TrustRule.vertical(),
                  Expanded(child: _TrustLine(point: slice[c])),
                ],
                // A short final run keeps its empty columns rather than
                // stretching the cells it does have — the same rule the
                // page's grids follow.
                for (var c = slice.length; c < columns; c++)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        }

        return LandingCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        );
      },
    );
  }
}

/// The rule between two trust lines.
///
/// The vertical one is a fixed short stroke rather than a full-height
/// divider: matching the tallest cell would need an [IntrinsicHeight], which
/// hands every cell tight constraints and freezes the row's height against
/// whichever font face happened to be loaded when it was measured.
class _TrustRule extends StatelessWidget {
  const _TrustRule.vertical() : _vertical = true;
  const _TrustRule.horizontal() : _vertical = false;

  final bool _vertical;

  @override
  Widget build(BuildContext context) {
    if (_vertical) {
      return Container(
        width: 1,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        color: LandingPalette.border,
      );
    }
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: LandingPalette.border,
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
        // A bare glyph rather than a tinted tile: four tiles in a row under
        // the rig read as a second set of cards competing with the devices
        // above them, where four marks read as punctuation on one strip.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(point.icon, size: 19, color: LandingPalette.brand),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(point.title, style: LandingType.cardTitle(14)),
              const SizedBox(height: 2),
              Text(
                point.body,
                style: LandingType.cardBody(12.5).copyWith(height: 1.6),
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
/// Wide, the three devices stand in one row on a common floor line, the
/// console between the two phones. Below that width a console shrunk to a
/// third of the column stops being a screen at all, so it takes the full
/// column and the two phones line up beneath it.
class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 940) {
          final phone = _rigPhoneWidth(width);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroRig(width: width),
              const SizedBox(height: 18),
              _HeroSurfaceKey.spread(phoneWidth: phone),
            ],
          );
        }
        // Two phones and the gap between them, never wider than the column
        // and never so small the screen inside stops being readable.
        final phone = ((width - 16) / 2).clamp(112.0, 186.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroStack(phoneWidth: phone),
            const SizedBox(height: 16),
            const _HeroSurfaceKey.centred(),
          ],
        );
      },
    );
  }
}

/// The phone width the wide rig uses — stated once, because the key under it
/// lines its columns up against the same number.
double _rigPhoneWidth(double width) => (width * 0.165).clamp(160.0, 215.0);

/// The air between a phone and the console. Enough that the three devices
/// are separate objects, tight enough that they are still one group.
double _rigGap(double phoneWidth) => phoneWidth * 0.10;

class _HeroRig extends StatelessWidget {
  const _HeroRig({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final phone = _rigPhoneWidth(width);

    // Bottom-aligned rather than overlapped: three screens standing on one
    // floor line read as three surfaces of one system, where a phone lapped
    // over the console reads as a phone in front of a picture of a console.
    // Start → end in RTL is right → left, which is the order the key under
    // the rig names them in: captain, console, rider.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LandingPhoneFrame(width: phone, child: const LandingCaptainBoard()),
        SizedBox(width: _rigGap(phone)),
        const Expanded(
          child: LandingBrowserFrame(child: LandingConsoleBoard()),
        ),
        SizedBox(width: _rigGap(phone)),
        LandingPhoneFrame(width: phone, child: const LandingRiderBoard()),
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
        const LandingBrowserFrame(child: LandingConsoleBoard()),
        SizedBox(height: phoneWidth * 0.14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LandingPhoneFrame(
              width: phoneWidth,
              child: const LandingCaptainBoard(),
            ),
            const SizedBox(width: 14),
            LandingPhoneFrame(
              width: phoneWidth,
              child: const LandingRiderBoard(),
            ),
          ],
        ),
      ],
    );
  }
}
