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
    this.note,
  });

  final PackagePlan plan;
  final double price;
  final double singleRideFare;

  /// What the office wrote about this package on this trip — terms the rider
  /// should read before choosing it ("تشمل رحلة العودة"). Null when they
  /// wrote none. Per trip, not per package: the same package can carry a
  /// different note on another departure.
  final String? note;

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
                  if (note != null && note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _PackageNote(note: note!.trim(), accent: accent),
                  ],
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

class _PackageNote extends StatelessWidget {
  const _PackageNote({required this.note, required this.accent});

  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(16),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note, style: ClientTypography.bodySmall(context)),
          ),
        ],
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
