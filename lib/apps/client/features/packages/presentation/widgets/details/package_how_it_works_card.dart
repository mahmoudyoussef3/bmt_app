import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'package_detail_section.dart';

/// The three steps between reading about a plan and riding on it.
///
/// Subscribing is not a one-tap purchase here — a package binds to a route and
/// is priced on it — so the pane says that up front rather than letting the CTA
/// surprise the rider with a route picker.
class PackageHowItWorksCard extends StatelessWidget {
  const PackageHowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final steps = <({String title, String body})>[
      (title: l10n.packages_step1Title, body: l10n.packages_step1Body),
      (title: l10n.packages_step2Title, body: l10n.packages_step2Body),
      (title: l10n.packages_step3Title, body: l10n.packages_step3Body),
    ];

    return PackageDetailSection(
      icon: Icons.play_circle_outline_rounded,
      title: l10n.packages_howItWorks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, step) in steps.indexed)
            _Step(
              number: index + 1,
              title: step.title,
              body: step.body,
              isLast: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

/// A numbered step on a spine, so the three read as a sequence rather than as
/// three unrelated facts.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.isLast,
  });

  final int number;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const accent = ClientColors.journeyPurple;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: accent.withAlpha(40)),
                ),
            ],
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : ClientSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
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
