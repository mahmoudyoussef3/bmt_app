import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_layout.dart';

/// «من إدارة مشتتة... إلى تشغيل منظم» — the before/after pair.
///
/// The two panels are deliberately unequal: "before" is a flat muted card,
/// "after" carries the brand tint, a brand border and the only shadow in the
/// section, so the comparison is legible before a word of it is read.
class ComparisonSection extends StatelessWidget {
  const ComparisonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LandingSectionIntro(
            headline: 'من إدارة مشتتة... إلى تشغيل منظم',
            align: TextAlign.center,
            center: true,
            maxWidth: 720,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          const LandingAutoGrid(
            minItemWidth: 300,
            spacing: 14,
            maxColumns: 2,
            children: [_BeforePanel(), _AfterPanel()],
          ),
        ],
      ),
    );
  }
}

class _BeforePanel extends StatelessWidget {
  const _BeforePanel();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(22),
      background: LandingPalette.surface2,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: LandingPalette.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 21,
                  color: LandingPalette.muted,
                ),
                const SizedBox(width: 9),
                Text(
                  'قبل EWT',
                  style: LandingType.cardTitle(
                    16.5,
                    color: LandingPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (index, item) in LandingContent.before.indexed) ...[
            if (index > 0) const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: LandingPalette.faint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: LandingType.label(13.5, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AfterPanel extends StatelessWidget {
  const _AfterPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: LandingPalette.brandLine),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LandingPalette.brandTint, LandingPalette.surface],
        ),
        boxShadow: [
          BoxShadow(
            color: LandingPalette.brand.withValues(alpha: 0.4),
            offset: const Offset(0, 22),
            blurRadius: 44,
            spreadRadius: -28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: LandingPalette.brandLine),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 21,
                  color: LandingPalette.brand,
                ),
                const SizedBox(width: 9),
                Text(
                  'مع EWT',
                  style: LandingType.cardTitle(
                    16.5,
                    color: LandingPalette.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (index, item) in LandingContent.after.indexed) ...[
            if (index > 0) const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: LandingPalette.brand,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: LandingType.label(
                      13.5,
                      color: LandingPalette.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
