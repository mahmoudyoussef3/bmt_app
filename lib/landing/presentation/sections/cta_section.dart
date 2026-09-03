import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_contact.dart';
import '../widgets/landing_layout.dart';

/// The closing conversion band — a navy panel split into the ask and the
/// ways to answer it.
///
/// The nav's «تواصل معنا» link scrolls here, so the band has to *be* the
/// contact surface rather than a button that opens one: the copy and the one
/// primary action lead, and the office's two real channels sit beside them,
/// tappable, on the panel. That also gives the second half of the card a job
/// — it used to hold nothing but a decorative wireframe that drifted under
/// the buttons and fought the label it sat behind.
class CtaSection extends StatelessWidget {
  const CtaSection({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: landingSectionGap(context)),
      child: LandingContainer(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LandingRadii.card + 10),
            boxShadow: LandingPalette.liftedShadow,
            // Flat navy, like every other dark band on the page (steps,
            // footer): the indigo end of the old gradient read as a second
            // brand colour and pulled the eye away from the copy.
            color: LandingPalette.navy,
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: AlignmentDirectional(-0.76, -0.84),
                      radius: 0.9,
                      colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
                      stops: [0, 0.62],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: landingClamp(context, min: 22, vw: 3.8, max: 56),
                  vertical: landingClamp(context, min: 34, vw: 4.6, max: 64),
                ),
                child: LandingSplit(
                  // The two 400px flex bases: below this the ask stacks over
                  // the channels rather than squeezing both.
                  breakpoint: 860,
                  startFlex: 6,
                  endFlex: 5,
                  gap: landingClamp(context, min: 30, vw: 3.4, max: 52),
                  start: _CtaAsk(onGetStarted: onGetStarted),
                  end: const _CtaChannels(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eyebrow, headline, lead, the page's one closing action, and the three
/// things that follow it.
class _CtaAsk extends StatelessWidget {
  const _CtaAsk({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final headline = landingClamp(context, min: 25, vw: 3.4, max: 42);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ابدأ الآن',
          style: LandingType.eyebrow(color: LandingPalette.onNavyAccent),
        ),
        const SizedBox(height: 12),
        Text(
          'جاهز تدير مكتبك بشكل أذكى؟',
          style: LandingType.heading(
            headline,
            color: Colors.white,
          ).copyWith(letterSpacing: -1, height: 1.28),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'ابدأ مع EWT وخلي إدارة الرحلات والحجوزات والكباتن '
            'والمدفوعات أسهل وأكثر تنظيمًا.',
            style: LandingType.lead(
              16,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: LandingButton(
              label: 'ابدأ مع EWT',
              icon: Icons.arrow_back_rounded,
              style: LandingButtonStyle.onDark,
              expand: true,
              onPressed: onGetStarted,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            for (final line in LandingContent.ctaAssurances)
              _Assurance(label: line),
          ],
        ),
      ],
    );
  }
}

class _Assurance extends StatelessWidget {
  const _Assurance({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: LandingPalette.onNavyAccent,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: LandingType.label(
              12.5,
              color: Colors.white.withValues(alpha: 0.7),
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// The glass panel: the two channels the office really answers on.
class _CtaChannels extends StatelessWidget {
  const _CtaChannels();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LandingRadii.card + 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LandingIconSquare(
                icon: Icons.support_agent_rounded,
                size: 38,
                iconSize: 19,
                radius: 11,
                background: Colors.white.withValues(alpha: 0.10),
                borderColor: Colors.white.withValues(alpha: 0.18),
                iconColor: LandingPalette.onNavyAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تواصل معنا مباشرة',
                      style: LandingType.cardTitle(15, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'اختر الطريقة الأنسب لك.',
                      style: LandingType.label(
                        12,
                        color: Colors.white.withValues(alpha: 0.6),
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (index, channel) in LandingChannel.values.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            LandingChannelTile(channel: channel),
          ],
        ],
      ),
    );
  }
}
