import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import '../package_office_badge.dart';
import '../package_stat_column.dart';
import 'package_card_price_row.dart';

class PackageCardBody extends StatelessWidget {
  const PackageCardBody({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          package.displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (package.hasOffice) ...[
          const SizedBox(height: 8),
          PackageOfficeBadge(package: package),
        ],
        const SizedBox(height: 12),
        // Each stat takes an equal share so long Arabic labels wrap within their
        // column on a small phone instead of overflowing the row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PackageStatColumn(
                label: l10n.packages_duration,
                value: l10n.packages_daysCount(package.durationDays),
              ),
            ),
            Expanded(
              child: PackageStatColumn(
                label: l10n.packages_totalTrips,
                value: l10n.packages_ridesCount(package.rideCount),
              ),
            ),
            Expanded(
              child: PackageStatColumn(
                label: l10n.packages_perRide,
                value: FormatUtil.currency(context, package.pricePerRide),
                valueColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 14),
        PackageCardPriceRow(package: package),
      ],
    );
  }
}
