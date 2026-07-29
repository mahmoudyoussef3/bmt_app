import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import '../package_stat_column.dart';

/// What the package costs, next to what a single ride inside it works out to.
class PackagePriceSummary extends StatelessWidget {
  const PackagePriceSummary({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PackageStatColumn(
          label: l10n.packages_perRide,
          value: FormatUtil.currency(context, package.pricePerRide),
          valueColor: scheme.secondary,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.packages_subscriptionCost,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              FormatUtil.currency(context, package.priceInPounds),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
