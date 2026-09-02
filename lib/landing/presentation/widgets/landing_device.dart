import 'package:flutter/material.dart';

import '../theme/landing_theme.dart';
import 'landing_shots.dart';

// Every section that frames a shot needs its path, so the two travel
// together rather than making each caller import both files.
export 'landing_shots.dart';

/// The screenshot itself: pinned to its capture's aspect ratio, anchored to
/// the top edge, and faded in once the decode lands.
///
/// The aspect ratio is stated rather than measured so the page lays out
/// identically before and after the image decodes — a shot that resized on
/// arrival would reflow the section under the reader's scroll.
class _ShotImage extends StatelessWidget {
  const _ShotImage({
    required this.asset,
    required this.aspectRatio,
    required this.background,
    this.crop = 0,
    this.fadeCut = false,
  });

  final String asset;
  final double aspectRatio;
  final Color background;

  /// How much of the capture's bottom edge to cut away, as a fraction of its
  /// height. Used where a shot is meant to run off the bottom of its frame
  /// rather than end on whatever row the capture happened to stop at.
  final double crop;

  /// Wash the cut edge out to [background]. Right for a browser window, where
  /// a page genuinely continues past the fold; wrong for a phone, where the
  /// device has a real bottom edge and a fade would only look like a bug.
  final bool fadeCut;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: crop == 0 ? aspectRatio : aspectRatio / (1 - crop),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: background,
            child: Image.asset(
              asset,
              // Anchored to the top edge: a capture cropped from the bottom is
              // cut where the screen has least to say, not through its header.
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
              // A missing capture must not take the section down with it — the
              // frame keeps its shape and the band still reads.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              frameBuilder: (_, child, frame, wasSync) => AnimatedOpacity(
                opacity: wasSync || frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                child: child,
              ),
            ),
          ),
          // A cropped shot otherwise ends on a hard line through whatever row
          // the cut landed in, which reads as a rendering fault rather than a
          // screen that carries on. The wash says "there is more below".
          if (crop > 0 && fadeCut)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [background.withValues(alpha: 0), background],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rider- or captain-app capture inside a drawn phone body.
///
/// The body carries no notch: these captures start at the app's own header
/// row, so an island drawn over them would sit on top of real product chrome.
class LandingPhoneShot extends StatelessWidget {
  const LandingPhoneShot({
    super.key,
    required this.asset,
    this.width = 240,
    this.tilt = 0,
    this.crop = 0,
    this.shadow = true,
  });

  final String asset;
  final double width;

  /// A small rotation, in radians, for phones stacked behind another.
  final double tilt;
  final double crop;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    // The bezel and corner radii are proportional so a 160px phone and a
    // 300px one read as the same object at two distances.
    final bezel = width * 0.037;
    final outer = width * 0.155;

    final phone = SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(bezel),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF223148), LandingPalette.navy],
          ),
          borderRadius: BorderRadius.circular(outer),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: LandingPalette.navy.withValues(alpha: 0.42),
                    offset: const Offset(0, 26),
                    blurRadius: 54,
                    spreadRadius: -24,
                  ),
                  const BoxShadow(
                    color: Color(0x141C1917),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outer - bezel),
          child: _ShotImage(
            asset: asset,
            aspectRatio: LandingShots.phoneAspect,
            background: LandingPalette.surface,
            crop: crop,
          ),
        ),
      ),
    );

    return tilt == 0 ? phone : Transform.rotate(angle: tilt, child: phone);
  }
}

/// A console capture inside a browser window.
///
/// The chrome is deliberately minimal — three dots and the address — because
/// the point it makes is "this runs in the browser you already have", and
/// anything more detailed competes with the screen it is framing.
class LandingBrowserShot extends StatelessWidget {
  const LandingBrowserShot({
    super.key,
    required this.asset,
    this.url = 'console.ewt.eg',
    this.crop = 0,
    this.radius = LandingRadii.card + 8,
    this.borderColor = LandingPalette.border,
    this.shadow = LandingPalette.liftedShadow,
  });

  final String asset;
  final String url;
  final double crop;
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrowserBar(url: url),
          _ShotImage(
            asset: asset,
            aspectRatio: LandingShots.consoleAspect,
            background: LandingPalette.page,
            crop: crop,
            fadeCut: true,
          ),
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
    final wide = MediaQuery.sizeOf(context).width >= 620;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: LandingPalette.surface2,
        border: Border(bottom: BorderSide(color: LandingPalette.border)),
      ),
      child: Row(
        children: [
          for (final _ in const [0, 1, 2]) ...[
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: LandingPalette.borderStrong,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          if (wide)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LandingPalette.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: LandingPalette.border),
                  ),
                  // A URL is a Latin run: in an RTL page it needs its own
                  // direction or the dot-separated parts reorder.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: LandingPalette.faint,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            url,
                            style: LandingType.label(
                              11,
                              color: LandingPalette.faint,
                              weight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

/// A small translucent card that floats over a product shot — one number the
/// screenshot behind it is too dense to make on its own.
class LandingShotOverlayCard extends StatelessWidget {
  const LandingShotOverlayCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = LandingPalette.brand,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: LandingPalette.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LandingPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D0B1B34),
            offset: Offset(0, 14),
            blurRadius: 32,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: tone),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: LandingType.label(10.5)),
              const SizedBox(height: 2),
              Text(
                value,
                style: LandingType.metric(
                  16,
                ).copyWith(letterSpacing: -0.4, height: 1.15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two captures from the same app, one tucked behind the other.
///
/// A single phone shows one screen; a pair shows that the app is a *place*,
/// with somewhere to go from the screen in front. The back phone is smaller
/// and set higher so the depth reads without either screen being hidden.
class LandingPhoneDuo extends StatelessWidget {
  const LandingPhoneDuo({
    super.key,
    required this.frontAsset,
    required this.backAsset,
    this.width = 220,
  });

  final String frontAsset;
  final String backAsset;

  /// The width of the *front* phone; the whole pair is 1.44x this.
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // The back phone is offset out past the front one's shoulder.
      clipBehavior: Clip.none,
      children: [
        // Declared first, so it paints first — a Stack paints in child order,
        // and a "back" phone drawn last would sit on top of the front one.
        PositionedDirectional(
          end: 0,
          top: 0,
          child: LandingPhoneShot(
            asset: backAsset,
            width: width * 0.80,
            tilt: 0.04,
          ),
        ),
        // Not positioned, so this child is what the Stack sizes itself to —
        // a pair of positioned phones alone would have no height to take.
        Padding(
          // The offset is what is left showing of the phone behind, so it
          // has to be wide enough to read as a screen rather than an edge.
          padding: EdgeInsetsDirectional.only(
            end: width * 0.44,
            top: width * 0.12,
          ),
          child: LandingPhoneShot(asset: frontAsset, width: width),
        ),
      ],
    );
  }
}
