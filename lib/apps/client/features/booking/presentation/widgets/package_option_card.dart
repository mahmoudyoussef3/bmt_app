import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/package_option_parts.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// One fare option in the booking wizard's package step.
///
/// [price] is the Dashboard-configured fare for the rider's exact
/// pickup -> dropoff pair (see `BookingWizardSession.resolvedPackagePrice`),
/// and [singleRideFare] is that same pair's one-time fare — so the "regular
/// total" struck through here is what buying every ride separately actually
/// costs on this trip, not a catalog approximation.
class PackageOptionCard extends StatelessWidget {
  const PackageOptionCard({
    super.key,
    required this.plan,
    required this.price,
    required this.singleRideFare,
    required this.isFeatured,
    required this.isSelected,
    required this.onTap,
  });

  final PackagePlan plan;
  final double price;
  final double singleRideFare;
  final bool isFeatured;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);
    final regularTotal = singleRideFare * plan.rideCount;
    final savings = regularTotal > price ? regularTotal - price : 0.0;
    final discount = savings > 0 ? ((savings / regularTotal) * 100).round() : 0;

    return GestureDetector(
      onTap: onTap,
      child: BookingSurfaceCard(
        selected: isSelected,
        accentColor: accent,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFeatured) _FeaturedRibbon(accent: accent),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PackagePlanHeader(
                    plan: plan,
                    accent: accent,
                    isSelected: isSelected,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: PackagePriceBlock(
                          price: price,
                          regularTotal: savings > 0 ? regularTotal : null,
                          perRide: plan.rideCount > 1
                              ? price / plan.rideCount
                              : null,
                        ),
                      ),
                      if (discount > 0)
                        BookingCountPill(
                          label: context.l10n.booking_saveDiscountPercent(
                            discount,
                          ),
                          color: ClientColors.journeyCyan,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedRibbon extends StatelessWidget {
  const _FeaturedRibbon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg - 1),
        ),
      ),
      child: Text(
        context.l10n.booking_bestValue,
        textAlign: TextAlign.center,
        style: ClientTypography.labelSmall(context).copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
