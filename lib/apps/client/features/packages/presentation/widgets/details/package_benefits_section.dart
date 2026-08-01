import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'package_benefit_row.dart';
import 'package_detail_section.dart';

class PackageBenefitsSection extends StatelessWidget {
  const PackageBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PackageDetailSection(
      icon: Icons.verified_outlined,
      title: l10n.packages_whatIsIncluded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PackageBenefitRow(
            icon: Icons.event_seat_rounded,
            title: l10n.packages_reservedSeatGuaranteed,
            description: l10n.packages_reservedSeatDesc,
          ),
          const SizedBox(height: ClientSpacing.md),
          PackageBenefitRow(
            icon: Icons.schedule_rounded,
            title: l10n.packages_flexibleTiming,
            description: l10n.packages_flexibleTimingDesc,
          ),
        ],
      ),
    );
  }
}
