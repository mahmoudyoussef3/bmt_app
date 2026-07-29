import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// One of the office's commute packages, as it appears on the office profile:
/// name, the duration/ride shape, and price. Tapping opens this exact
/// package's detail pane in the marketplace, the same way `PackageCard` does
/// from the listing.
class OfficePackageTile extends StatelessWidget {
  const OfficePackageTile({
    super.key,
    required this.package,
    required this.onTap,
  });

  final PackagePlan package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ClientCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(ClientRadius.md),
            ),
            child: Icon(
              Icons.confirmation_number_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.packages_daysCount(package.durationDays)} · '
                  '${l10n.packages_ridesCount(package.rideCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatUtil.currency(context, package.priceInPounds),
                style: ClientTypography.priceSmall(
                  context,
                ).copyWith(color: scheme.primary, fontWeight: FontWeight.w900),
              ),
              Text(
                l10n.packages_startingPrice,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
