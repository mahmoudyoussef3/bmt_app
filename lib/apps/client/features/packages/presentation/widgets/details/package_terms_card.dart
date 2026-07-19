import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import 'package_info_panel.dart';
import 'package_section_title.dart';

class PackageTermsCard extends StatelessWidget {
  const PackageTermsCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PackageSectionTitle(title: l10n.packages_termsCancellation),
        const SizedBox(height: 10),
        PackageInfoPanel(
          child: Text(
            '${l10n.packages_termsText1}\n'
            '${l10n.packages_termsText2}\n'
            '${l10n.packages_termsText3(package.rideCount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: scheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ],
    );
  }
}
