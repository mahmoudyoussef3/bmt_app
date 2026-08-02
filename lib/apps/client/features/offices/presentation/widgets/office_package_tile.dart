import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/widgets/package_shape_chips.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// One of the office's commute packages, as it appears on the office profile:
/// what it is and what it bundles, never what it costs.
///
/// A package has no single price — the same plan is priced per corridor, so the
/// catalogue figure would be a number the rider never actually pays. The tile
/// says so plainly instead, and the real amount is quoted in the booking flow
/// once a route exists to price against.
///
/// Read-only for the same reason: there is nowhere to send a tap that could
/// price the plan. The rider chooses one in the booking wizard's package step,
/// after picking the route it will be priced against.
class OfficePackageTile extends StatelessWidget {
  const OfficePackageTile({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const accent = ClientColors.journeyPurple;

    return ClientCard(
      padding: const EdgeInsets.all(ClientSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withAlpha(24),
              borderRadius: BorderRadius.circular(ClientRadius.md),
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                PackageShapeChips(package: package, accent: accent),
                const SizedBox(height: 6),
                Text(
                  l10n.packages_priceAtBooking,
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
