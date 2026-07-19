import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'package_benefit_row.dart';
import 'package_section_title.dart';

class PackageBenefitsSection extends StatelessWidget {
  const PackageBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_whatIsIncluded),
        const SizedBox(height: 10),
        PackageBenefitRow(
          icon: Icons.event_seat_rounded,
          title: l10n.packages_reservedSeatGuaranteed,
          description: l10n.packages_reservedSeatDesc,
        ),
        PackageBenefitRow(
          icon: Icons.schedule_rounded,
          title: l10n.packages_flexibleTiming,
          description: l10n.packages_flexibleTimingDesc,
        ),
      ],
    );
  }
}
