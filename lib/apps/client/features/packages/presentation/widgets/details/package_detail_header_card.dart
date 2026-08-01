import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';

/// The pane's masthead: which plan this is, and the two numbers that define it.
///
/// It carries no price. The same plan is priced per corridor, so a headline
/// figure here would be a number the rider never pays — the amount is quoted in
/// the booking flow, once a route exists to price against.
class PackageDetailHeaderCard extends StatelessWidget {
  const PackageDetailHeaderCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    const accent = ClientColors.journeyPurple;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [accent.withAlpha(isDark ? 46 : 28), accent.withAlpha(0)],
        ),
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: ClientSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.packages_commutePackages,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: accent, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      package.displayName,
                      style: ClientTypography.headingMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClientSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShapeStat(
                  icon: Icons.calendar_month_rounded,
                  value: '${package.durationDays}',
                  label: context.l10n.packages_duration,
                ),
              ),
              const SizedBox(width: ClientSpacing.xs),
              Expanded(
                child: _ShapeStat(
                  icon: Icons.event_seat_rounded,
                  value: '${package.rideCount}',
                  label: context.l10n.packages_totalTrips,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two numbers that define a plan, given the weight the price used
/// to hold — days and rides are now the headline facts of a package.
class _ShapeStat extends StatelessWidget {
  const _ShapeStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.sm,
        vertical: ClientSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context).withAlpha(200),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ClientColors.journeyPurple),
          const SizedBox(width: ClientSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
