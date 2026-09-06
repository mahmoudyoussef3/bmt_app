import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_layout.dart';

/// «من إدارة مشتتة... إلى تشغيل منظم» — the before and after, side by side.
class ComparisonSection extends StatelessWidget {
  const ComparisonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LandingContent.comparisonHeadline,
            textAlign: TextAlign.center,
            style: LandingType.heading(
              landingClamp(context, min: 25, vw: 3.2, max: 40),
            ),
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          const LandingAutoGrid(
            minItemWidth: 300,
            spacing: 14,
            stagger: true,
            children: [_BeforeCard(), _AfterCard()],
          ),
        ],
      ),
    );
  }
}

class _BeforeCard extends StatelessWidget {
  const _BeforeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LandingPalette.surface2,
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: LandingPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardHeading(
            icon: Icons.error_outline_rounded,
            iconColor: LandingPalette.muted,
            label: LandingContent.comparisonBeforeTitle,
            labelColor: LandingPalette.muted,
            ruleColor: LandingPalette.border,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < LandingContent.comparisonBefore.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            _ListRow(
              icon: Icons.close_rounded,
              iconColor: LandingPalette.faint,
              label: LandingContent.comparisonBefore[i],
              labelColor: LandingPalette.muted,
              weight: FontWeight.w600,
            ),
          ],
        ],
      ),
    );
  }
}

class _AfterCard extends StatelessWidget {
  const _AfterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // `linear-gradient(160deg, …)` — a physical angle, down and barely to
        // the right, which does not mirror with the page direction.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LandingPalette.brandTint, LandingPalette.surface],
        ),
        borderRadius: LandingRadii.cardR,
        border: Border.all(color: LandingPalette.brandLine),
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
          _CardHeading(
            icon: Icons.check_circle_rounded,
            iconColor: LandingPalette.brand,
            label: LandingContent.comparisonAfterTitle,
            labelColor: LandingPalette.navy,
            ruleColor: LandingPalette.brandLine,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < LandingContent.comparisonAfter.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            _ListRow(
              icon: Icons.check_rounded,
              iconColor: LandingPalette.brand,
              label: LandingContent.comparisonAfter[i],
              labelColor: LandingPalette.ink,
              weight: FontWeight.w700,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.ruleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Color ruleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ruleColor)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: LandingType.metric(
                16.5,
                color: labelColor,
              ).copyWith(letterSpacing: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.weight,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: LandingType.label(13.5, color: labelColor, weight: weight),
          ),
        ),
      ],
    );
  }
}
