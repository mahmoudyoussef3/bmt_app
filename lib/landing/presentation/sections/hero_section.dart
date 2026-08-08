import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_typography.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import '../widgets/landing_button.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_shot.dart';
import '../widgets/landing_reveal.dart';

/// The opening section — the one screen a visitor decides whether to keep
/// reading from. Headline + supporting line + the two CTAs on one side, the
/// three products on the other: the console with the client and captain apps
/// at its shoulders.
///
/// The rig is a real screenshot of each app, not an illustration of one. It
/// carries no copy of its own so the headline beside it is the only claim on
/// the screen.
///
/// Below `1080` the shot drops beneath the copy rather than beside it —
/// there is no width left to show a product screenshot at a readable scale
/// next to a headline.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onSeeProduct,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSeeProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    final mobile = LandingContainer.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary.withAlpha(16), scheme.surface],
        ),
      ),
      child: LandingContainer(
        maxWidth: 1280,
        child: Padding(
          padding: EdgeInsets.only(
            top: mobile ? 40 : 72,
            bottom: mobile ? 48 : 88,
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _HeroCopy(
                        onGetStarted: onGetStarted,
                        onSeeProduct: onSeeProduct,
                      ),
                    ),
                    const SizedBox(width: 48),
                    // The rig is three screenshots wide; give it the larger
                    // half or the console inside it stops being readable.
                    const Expanded(
                      flex: 6,
                      child: LandingShot(asset: 'ewt-ecosystem-devices'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCopy(onGetStarted: onGetStarted, onSeeProduct: onSeeProduct),
                    const SizedBox(height: AppSpacing.xLarge),
                    const LandingReveal(
                      child: LandingShot(asset: 'ewt-ecosystem-devices'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onGetStarted, required this.onSeeProduct});

  final VoidCallback onGetStarted;
  final VoidCallback onSeeProduct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = LandingContainer.isMobile(context);
    final crossAxis = mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = mobile ? TextAlign.center : TextAlign.start;

    return LandingReveal(
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.primary.withAlpha(60)),
            ),
            child: Text(
              'منصة إدارة النقل — Easy Way Transportation',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            'إدارة أعمال النقل بالكامل من مكان واحد',
            textAlign: textAlign,
            style: AppTypography.heading1(
              scheme,
            ).copyWith(fontSize: mobile ? 32 : 44, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.medium),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'EWT منصة متكاملة تساعد مكاتب النقل على إدارة الرحلات والعملاء '
              'والسائقين والمركبات والحجوزات والمدفوعات، مع تقارير ذكية تساعدك '
              'على اتخاذ قرارات أفضل.',
              textAlign: textAlign,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Wrap(
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              LandingButton.primary(
                label: 'ابدأ مع EWT',
                icon: Icons.arrow_back_rounded,
                onPressed: onGetStarted,
              ),
              LandingButton.secondary(
                label: 'شاهد كيف تعمل المنصة',
                onPressed: onSeeProduct,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
