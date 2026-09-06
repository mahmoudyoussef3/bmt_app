import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';

/// The device and browser shells the page's product mockups sit in.
///
/// Every mockup in the design is authored at a fixed pixel width — the phones
/// are 208px, 250px and 290px wide — so each shell lays its child out at that
/// design width and scales the finished board down to whatever slot it is
/// given, exactly as an image would. Nothing inside a phone branches on width,
/// which is what keeps the 320 → 1600 sweep free of one-off responsive rules.
/// The phones hold real captures of the apps ([LandingShots]); the console
/// stays a drawing.

/// The real product captures the page's phones show.
///
/// Every one of these is a photograph of the shipping app, taken by
/// `tool/showcase` over invented demo data — no production row is in any of
/// them, and none is a drawing of a screen we wish we had. Regenerate them
/// with `node tool/showcase/capture/landing_assets.mjs` after a UI change (the
/// README next to it has the full three-command run).
///
/// The device body is *not* baked into the file: [LandingPhoneShell] draws it
/// in Flutter, so a capture appears at any size without its chrome resampling
/// with it, and a palette change here does not mean re-photographing the app.
/// The console mockup is drawn rather than photographed — a 1600px console
/// shown at a third of the page's width is a wall of 9px type.
class LandingShots {
  const LandingShots._();

  static const _dir = 'assets/showcase';

  /// Captured at 390x844 logical, which is what the phone screens size to.
  static const double phoneAspect = 390 / 844;

  /// The rider app: the fold's screen, and the seat picker it books on.
  static const clientHome = '$_dir/shot-client-home.webp';
  static const clientSeats = '$_dir/shot-client-seats.webp';

  /// The captain app: the day's assignment list, and a trip under way.
  static const captainHome = '$_dir/shot-captain-home.webp';
  static const captainTrip = '$_dir/shot-captain-trip.webp';
}

/// A capture filling a phone's screen, pinned to the aspect ratio it was taken
/// at and anchored to its top edge.
///
/// The ratio is stated rather than measured so the band lays out identically
/// before and after the decode — a shot that resized on arrival would reflow
/// the section under the reader's scroll.
class LandingShotScreen extends StatelessWidget {
  const LandingShotScreen({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: LandingShots.phoneAspect,
      child: Image.asset(
        asset,
        // Anchored to the top, so a capture whose ratio drifts from the frame's
        // is trimmed at the foot rather than through its header.
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.medium,
        // A missing capture must not take the band down with it — the phone
        // keeps its shape and the copy beside it still reads.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        frameBuilder: (_, child, frame, wasSync) => AnimatedOpacity(
          opacity: wasSync || frame != null ? 1 : 0,
          duration: const Duration(milliseconds: 260),
          child: child,
        ),
      ),
    );
  }
}

/// A phone: a navy body with a rounded screen cut out of it.
class LandingPhoneShell extends StatelessWidget {
  const LandingPhoneShell({
    super.key,
    required this.designWidth,
    required this.child,
    this.bodyPadding = 7,
    this.outerRadius = 30,
    this.innerRadius = 24,
    this.screenColor = LandingPalette.surface,
    this.shadow = const [
      BoxShadow(
        color: Color(0x800B1B34),
        offset: Offset(0, 30),
        blurRadius: 56,
        spreadRadius: -28,
      ),
      BoxShadow(color: Color(0x2E0B1B34), offset: Offset(0, 2), blurRadius: 6),
    ],
  });

  /// The width the [child] is authored against, body padding included.
  final double designWidth;
  final Widget child;
  final double bodyPadding;
  final double outerRadius;
  final double innerRadius;
  final Color screenColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final phone = Container(
      width: designWidth,
      padding: EdgeInsets.all(bodyPadding),
      decoration: BoxDecoration(
        color: LandingPalette.navy,
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: ColoredBox(color: screenColor, child: child),
      ),
    );
    return LandingScaledBoard(designWidth: designWidth, child: phone);
  }
}

/// Lays [child] out at [designWidth] and scales the result to fit the width it
/// is given — never up, so a board in a generous slot keeps its designed size.
class LandingScaledBoard extends StatelessWidget {
  const LandingScaledBoard({
    super.key,
    required this.designWidth,
    required this.child,
  });

  final double designWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : designWidth;
        final width = math.min(available, designWidth);
        return Center(
          child: SizedBox(
            width: width,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(width: designWidth, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// A desktop browser window: the traffic lights and an address pill over a
/// white page. Unlike the phones this one is fluid — the console it frames is
/// built from the same auto-fit grids the design uses, so it reflows rather
/// than scaling.
class LandingBrowserShell extends StatelessWidget {
  const LandingBrowserShell({
    super.key,
    required this.url,
    required this.child,
    this.radius = LandingRadii.card + 8,
    this.borderColor = LandingPalette.border,
    this.shadow = const [
      BoxShadow(
        color: Color(0x610B1B34),
        offset: Offset(0, 40),
        blurRadius: 80,
        spreadRadius: -36,
      ),
      BoxShadow(color: Color(0x0D1C1917), offset: Offset(0, 4), blurRadius: 14),
    ],
  });

  final String url;
  final Widget child;
  final double radius;
  final Color borderColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: LandingPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrowserBar(url: url),
          child,
        ],
      ),
    );
  }
}

class _BrowserBar extends StatelessWidget {
  const _BrowserBar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: LandingPalette.raised,
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            const _TrafficLight(),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LandingPalette.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LandingPalette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: LandingPalette.muted,
                  ),
                  const SizedBox(width: 6),
                  // The address is a Latin run inside an RTL page: without its
                  // own direction the dots reorder around the label.
                  Flexible(
                    child: Text(
                      url,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LandingType.label(11),
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

class _TrafficLight extends StatelessWidget {
  const _TrafficLight();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E1DA),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// The small green "live" dot the navy bands use beside a status line.
class LandingLiveDot extends StatelessWidget {
  const LandingLiveDot({super.key, this.size = 7});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: LandingPalette.live,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A number, seat count or time that must keep its own order inside Arabic
/// copy. `12 / 14` and `TR-1042` reorder without an explicit direction, and a
/// first-strong isolate is not enough when the run opens with a digit.
class LandingLatin extends StatelessWidget {
  const LandingLatin(
    this.text, {
    super.key,
    required this.style,
    this.align = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
