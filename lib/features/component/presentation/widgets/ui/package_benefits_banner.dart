import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/app_typography.dart';

/// Compact benefits header inside the packages card.
class PackageBenefitsBanner extends StatelessWidget {
  const PackageBenefitsBanner({super.key});

  static const _benefits = [
    (icon: Icons.savings_outlined, label: 'Save up to 30%'),
    (icon: Icons.event_seat_outlined, label: 'Reserved seat'),
    (icon: Icons.bolt_outlined, label: 'Priority boarding'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            scheme.primary.withAlpha(42),
            scheme.secondary.withAlpha(32),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppLayout.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppLayout.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(200),
                  borderRadius: BorderRadius.circular(AppLayout.radiusMd),
                ),
                child: Icon(
                  Icons.card_membership_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppLayout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commute smarter',
                      style: AppTypography.heading(
                        scheme,
                      ).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bundle trips · predictable pricing · less daily friction',
                      style: AppTypography.caption(
                        scheme,
                      ).copyWith(color: scheme.onSurface.withAlpha(175)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceMd),
          Wrap(
            spacing: AppLayout.spaceSm,
            runSpacing: AppLayout.spaceSm,
            children: _benefits
                .map(
                  (b) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.spaceMd,
                      vertical: AppLayout.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withAlpha(215),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.outline.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.icon, size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          b.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
