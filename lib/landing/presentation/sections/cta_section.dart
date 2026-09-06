import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// The closing panel: one dark slab carrying the ask.
class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.onGetStarted,
    required this.onContact,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      // The band sits directly under the section before it — its own panel
      // supplies the separation, so only the bottom rhythm is padded.
      padTop: false,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.symmetric(
          horizontal: landingClamp(context, min: 22, vw: 4, max: 60),
          vertical: landingClamp(context, min: 38, vw: 5, max: 72),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LandingRadii.card + 10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LandingPalette.navy,
              Color(0xFF14365E),
              LandingPalette.brandDeep,
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _CtaGlow())),
            ),
            // `inset-inline-start: -40px` — a logical inset, so this one does
            // follow the page direction and sits on the right in RTL.
            const PositionedDirectional(
              start: -40,
              bottom: -70,
              width: 420,
              child: IgnorePointer(
                child: Opacity(opacity: 0.14, child: LandingWireframe()),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LandingContent.ctaHeadline,
                      style: LandingType.heading(
                        landingClamp(context, min: 25, vw: 3.4, max: 42),
                        color: Colors.white,
                      ).copyWith(letterSpacing: -1, height: 1.28),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      LandingContent.ctaBody,
                      style: LandingType.lead(
                        16,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // `flex: 1 1 200px; max-width: 280px` and
                    // `flex: 1 1 170px; max-width: 240px` — both buttons grow
                    // to their caps rather than hugging their labels.
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: math.min(280, constraints.maxWidth),
                            child: LandingButton(
                              label: LandingContent.getStarted,
                              onPressed: onGetStarted,
                              style: LandingButtonStyle.onDark,
                              icon: Icons.arrow_forward_rounded,
                              expand: true,
                            ),
                          ),
                          SizedBox(
                            width: math.min(240, constraints.maxWidth),
                            child: LandingButton(
                              label: LandingContent.navContact,
                              onPressed: onContact,
                              style: LandingButtonStyle.onDarkOutline,
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `radial-gradient(600px 320px at 12% 8%, rgba(255,255,255,.1), transparent)`.
class _CtaGlow extends CustomPainter {
  const _CtaGlow();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.62],
            ).createShader(
              Rect.fromCenter(
                center: Offset(size.width * 0.12, size.height * 0.08),
                width: 1200,
                height: 640,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(_CtaGlow oldDelegate) => false;
}
