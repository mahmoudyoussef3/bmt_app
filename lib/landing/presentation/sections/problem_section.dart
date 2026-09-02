import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «التحدي» — the four pains, closed by a brand-tinted band that names EWT as
/// the answer and points at the dashboard section.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key, required this.onSeeDashboard});

  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'التحدي',
            eyebrowColor: LandingPalette.warn,
            headline: 'مكتبك كبر... وطريقة إدارته لازم تكبر معاه',
            lead:
                'مع زيادة الرحلات والكباتن والحجوزات، المتابعة اليدوية بتاخد '
                'وقت وبتخلي الوصول للصورة الكاملة أصعب.',
          ),
          SizedBox(height: landingClamp(context, min: 28, vw: 3.5, max: 44)),
          LandingAutoGrid(
            minItemWidth: 240,
            spacing: 13,
            children: [
              for (final problem in LandingContent.problems)
                _ProblemCard(point: problem),
            ],
          ),
          SizedBox(height: landingClamp(context, min: 24, vw: 3, max: 36)),
          _MergeBanner(onSeeDashboard: onSeeDashboard),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.point});

  final LandingPoint point;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      background: LandingPalette.surface2,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(point.icon, size: 22, color: LandingPalette.warn),
          const SizedBox(height: 12),
          Text(point.title, style: LandingType.cardTitle(16)),
          const SizedBox(height: 6),
          Text(point.body, style: LandingType.cardBody(13.5)),
        ],
      ),
    );
  }
}

class _MergeBanner extends StatelessWidget {
  const _MergeBanner({required this.onSeeDashboard});

  final VoidCallback onSeeDashboard;

  @override
  Widget build(BuildContext context) {
    final size = landingClamp(context, min: 17, vw: 2, max: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: LandingPalette.brandTint,
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: LandingPalette.brandLine),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.merge_rounded,
            size: 26,
            color: LandingPalette.brandInk,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'EWT تجمع كل ده في نظام واحد.',
              style: LandingType.heading(
                size,
                color: LandingPalette.navy,
              ).copyWith(letterSpacing: -0.4),
            ),
          ),
          LandingButton(
            label: 'شوف لوحة التحكم',
            icon: Icons.arrow_back_rounded,
            height: 44,
            style: LandingButtonStyle.navy,
            onPressed: onSeeDashboard,
          ),
        ],
      ),
    );
  }
}
