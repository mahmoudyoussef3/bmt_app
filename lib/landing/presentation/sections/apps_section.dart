import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import '../widgets/landing_container.dart';
import '../widgets/landing_reveal.dart';
import '../widgets/landing_section_header.dart';
import '../widgets/landing_shot.dart';

/// The two apps the office's customers and captains actually hold.
///
/// The console sections either side of this one describe what the office sees;
/// this one answers the question they raise — where does that information come
/// from, and who is it going to. Both shots are the shipped screens.
class AppsSection extends StatelessWidget {
  const AppsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: LandingContainer(
        maxWidth: 1160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LandingReveal(
              child: LandingSectionHeader(
                eyebrow: 'التطبيقات',
                title: 'مكتبك متصل بعملائك وكباتنك',
                description:
                    'العميل يحجز مقعده ويتابع تذكرته من تطبيقه، والكابتن ينفّذ '
                    'الرحلة ويسجّل صعود الركاب من تطبيقه — والمكتب يرى الاثنين '
                    'في لوحته لحظة بلحظة.',
              ),
            ),
            const SizedBox(height: 48),
            LandingReveal(
              child: wide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ClientShot()),
                        SizedBox(width: 64),
                        Expanded(child: _CaptainShot()),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ClientShot(),
                        SizedBox(height: AppSpacing.xLarge),
                        _CaptainShot(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientShot extends StatelessWidget {
  const _ClientShot();

  @override
  Widget build(BuildContext context) => const LandingShot(
    asset: 'ewt-shot-client',
    caption: 'تطبيق العميل — البحث عن رحلة، حجز مقعد، ومتابعة التذكرة.',
    maxWidth: 300,
  );
}

class _CaptainShot extends StatelessWidget {
  const _CaptainShot();

  @override
  Widget build(BuildContext context) => const LandingShot(
    asset: 'ewt-shot-captain',
    caption: 'تطبيق الكابتن — الخريطة المباشرة ونقطة التجميع القادمة.',
    maxWidth: 300,
  );
}
