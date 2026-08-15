import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Identity row of a [PackageOptionCard]: what the plan is, what it bundles,
/// and whether it is the rider's current pick.
class PackagePlanHeader extends StatelessWidget {
  const PackagePlanHeader({
    super.key,
    required this.plan,
    required this.accent,
    required this.isSelected,
  });

  final PackagePlan plan;
  final Color accent;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = plan.nameEn.trim().isEmpty ? plan.nameAr : plan.nameEn;
    final ridesValidDays = l10n.booking_ridesValidForDays(
      l10n.packages_ridesCount(plan.rideCount),
      l10n.packages_daysCount(plan.durationDays),
    );

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? accent : accent.withAlpha(20),
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          child: Icon(
            plan.rideCount == 1
                ? Icons.confirmation_number_outlined
                : Icons.event_repeat_rounded,
            size: 20,
            color: isSelected ? Colors.white : accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                ridesValidDays,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              if (plan.displayDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  plan.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: ClientMotion.base,
          child: isSelected
              ? Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('selected'),
                  size: 24,
                  color: accent,
                )
              : Icon(
                  Icons.radio_button_unchecked_rounded,
                  key: const ValueKey('empty'),
                  size: 24,
                  color: ClientColors.borderStrongFor(context),
                ),
        ),
      ],
    );
  }
}

/// Price row of a [PackageOptionCard]. [regularTotal] and [perRide] are shown
/// only when they say something the headline price doesn't — no strike-through
/// when the package costs the same as buying the rides one by one, and no
/// per-ride line on a single-ride fare.
class PackagePriceBlock extends StatelessWidget {
  const PackagePriceBlock({
    super.key,
    required this.price,
    this.regularTotal,
    this.perRide,
  });

  final double price;
  final double? regularTotal;
  final double? perRide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.packages_egpAmount(price.toStringAsFixed(0)),
              style: ClientTypography.priceMedium(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
            if (regularTotal != null) ...[
              const SizedBox(width: 8),
              
              Flexible(
                child: Text(
                  l10n.packages_egpAmount(regularTotal!.toStringAsFixed(0)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(context).copyWith(
                    color: ClientColors.textTertiaryFor(context),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (perRide != null) ...[
          const SizedBox(height: 3),
          Text(
            l10n.booking_pricePerRide(perRide!.toStringAsFixed(0)),
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}
