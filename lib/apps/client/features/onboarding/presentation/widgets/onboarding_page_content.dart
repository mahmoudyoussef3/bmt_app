import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../animations/fade_slide_transition.dart';

/// A single value proposition shown on one onboarding page.
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.accent,
    required this.scene,
    required this.features,
  });

  final String title;
  final String body;
  final Color accent;

  /// Premium hero artwork for this page (see [OnboardingScene]).
  final Widget scene;
  final List<OnboardingFeature> features;
}

class OnboardingFeature {
  const OnboardingFeature(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Premium onboarding page: an animated hero scene, headline, supporting copy,
/// and value-prop chips. Re-animates each time it becomes visible.
///
/// Vertically centers on roomy screens and scrolls on small phones / large text
/// scales so content is never clipped.
class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.data,
    required this.isVisible,
  });

  final OnboardingPageData data;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = (constraints.maxHeight * 0.46).clamp(190.0, 360.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: compact ? 8 : 16),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 60),
                        beginOffset: const Offset(0, 0.12),
                        child: SizedBox(
                          height: heroHeight,
                          width: double.infinity,
                          child: data.scene,
                        ),
                      ),
                      SizedBox(height: compact ? 22 : 34),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 160),
                        child: Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: ClientTypography.displayMedium(context)
                              .copyWith(
                                color: ClientColors.textPrimaryFor(context),
                                fontSize: size.width < 360 ? 26 : 30,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 240),
                        child: Text(
                          data.body,
                          textAlign: TextAlign.center,
                          style: ClientTypography.bodyLarge(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 320),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final feature in data.features)
                              _FeatureChip(
                                feature: feature,
                                accent: data.accent,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.feature, required this.accent});

  final OnboardingFeature feature;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 16, color: accent),
          const SizedBox(width: 7),
          Text(
            feature.label,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: accent, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
