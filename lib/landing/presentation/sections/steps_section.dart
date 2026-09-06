import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «كيف تعمل EWT؟» — four numbered steps on the page's second navy band.
class StepsSection extends StatelessWidget {
  const StepsSection({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final gap = landingSectionGap(context);
    return ColoredBox(
      color: LandingPalette.navy,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _StepsGlow())),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap),
            child: LandingContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LandingContent.stepsHeadline,
                    style: LandingType.heading(
                      landingClamp(context, min: 24, vw: 3.2, max: 38),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: landingClamp(context, min: 26, vw: 3.5, max: 42),
                  ),
                  LandingAutoGrid(
                    minItemWidth: 230,
                    spacing: 13,
                    stagger: true,
                    children: [
                      for (final step in LandingContent.steps)
                        _StepCard(step: step),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LandingButton(
                      label: LandingContent.getStarted,
                      onPressed: onGetStarted,
                      style: LandingButtonStyle.onDark,
                      icon: Icons.arrow_forward_rounded,
                      height: 52,
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

/// `radial-gradient(700px 360px at 10% 0%, rgba(37,99,235,.26), transparent)`.
class _StepsGlow extends CustomPainter {
  const _StepsGlow();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LandingPalette.brand.withValues(alpha: 0.26),
                LandingPalette.brand.withValues(alpha: 0),
              ],
              stops: const [0, 0.65],
            ).createShader(
              Rect.fromCenter(
                center: Offset(size.width * 0.1, 0),
                width: 1400,
                height: 720,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(_StepsGlow oldDelegate) => false;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final LandingStepCard step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                step.number,
                textDirection: TextDirection.ltr,
                style: LandingType.metric(
                  13,
                  color: LandingPalette.onNavyAccent,
                ).copyWith(letterSpacing: 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                step.icon,
                size: 19,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            step.title,
            style: LandingType.cardTitle(16.5, color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            step.body,
            style: LandingType.cardBody(
              13.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
