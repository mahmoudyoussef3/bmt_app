import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import '../package_detail_row.dart';
import 'package_info_panel.dart';
import 'package_section_title.dart';

class PackageRouteLimitsCard extends StatelessWidget {
  const PackageRouteLimitsCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_routeLimits),
        const SizedBox(height: 10),
        PackageInfoPanel(
          child: Column(
            children: [
              PackageDetailRow(
                label: l10n.packages_routeScope,
                value: l10n.packages_routeScopeDesc,
              ),
              const SizedBox(height: 8),
              PackageDetailRow(
                label: l10n.packages_includedRides,
                value: l10n.packages_singleTripsDesc(package.rideCount),
              ),
              const SizedBox(height: 8),
              PackageDetailRow(
                label: l10n.packages_validityPeriod,
                value: l10n.packages_consecutiveDaysDesc(package.durationDays),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
