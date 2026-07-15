import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The Routes tab's gradient hero: title, subtitle, and premium hero tags.
///
/// Uses the same [ClientColors.heroGradientFor] treatment as the Home tab
/// hero so both surfaces read as one BMT identity rather than two styles.
class RoutesHubHero extends StatelessWidget {
  const RoutesHubHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xl),
        boxShadow: ClientElevation.md(context),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(ClientSpacing.lg),
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -60,
            end: -40,
            child: _HeroOrb(size: 150, opacity: 0.10),
          ),
          const PositionedDirectional(
            bottom: -50,
            start: -30,
            child: _HeroOrb(size: 120, opacity: 0.07),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ClientTypography.headingLarge(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: ClientSpacing.xxs),
              Text(
                subtitle,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: Colors.white.withAlpha(210)),
              ),
              const SizedBox(height: ClientSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroTag(label: context.l10n.routes_tagFastDiscovery),
                  _HeroTag(label: context.l10n.routes_tagLiveAvailability),
                  _HeroTag(label: context.l10n.routes_tagPremiumRoutes),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}
