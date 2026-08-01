import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import '../package_detail_row.dart';
import 'package_detail_section.dart';

class PackageRouteLimitsCard extends StatelessWidget {
  const PackageRouteLimitsCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PackageDetailSection(
      icon: Icons.rule_rounded,
      title: l10n.packages_routeLimits,
      child: Column(
        children: [
          PackageDetailRow(
            label: l10n.packages_routeScope,
            value: l10n.packages_routeScopeDesc,
          ),
          const _RowDivider(),
          PackageDetailRow(
            label: l10n.packages_includedRides,
            value: l10n.packages_singleTripsDesc(package.rideCount),
          ),
          const _RowDivider(),
          PackageDetailRow(
            label: l10n.packages_validityPeriod,
            value: l10n.packages_consecutiveDaysDesc(package.durationDays),
          ),
        ],
      ),
    );
  }
}

/// A hairline between rows: three label/value pairs run together without one,
/// and a long wrapped value reads as belonging to the pair below it.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.sm),
      child: Divider(height: 1, color: ClientColors.borderFor(context)),
    );
  }
}
