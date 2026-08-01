import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

import '../../../domain/entities/package_plan.dart';
import '../package_office_badge.dart';
import '../package_shape_chips.dart';

/// A marketplace card: which plan, whose it is, and what it bundles.
///
/// It quotes no price. The same plan costs a different amount on every
/// corridor, so a headline figure here would be a number the rider never pays —
/// the card promises the price at the step that can actually produce one.
class PackageCardBody extends StatelessWidget {
  const PackageCardBody({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const accent = ClientColors.journeyPurple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(26),
                borderRadius: BorderRadius.circular(ClientRadius.sm),
              ),
              child: const Icon(
                Icons.card_membership_rounded,
                size: 20,
                color: accent,
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: Text(
                package.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        if (package.hasOffice) ...[
          const SizedBox(height: ClientSpacing.sm),
          PackageOfficeBadge(package: package),
        ],
        const SizedBox(height: ClientSpacing.sm),
        PackageShapeChips(package: package, accent: accent),
        const SizedBox(height: ClientSpacing.sm),
        Divider(height: 1, color: ClientColors.borderFor(context)),
        const SizedBox(height: ClientSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.sell_outlined,
              size: 14,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                l10n.packages_priceAtBooking,
                maxLines: 2,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: const DirectionalIcon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
