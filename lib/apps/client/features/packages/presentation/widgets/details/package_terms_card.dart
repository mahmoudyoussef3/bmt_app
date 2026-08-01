import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_plan.dart';
import 'package_detail_section.dart';

class PackageTermsCard extends StatelessWidget {
  const PackageTermsCard({super.key, required this.package});

  final PackagePlan package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final terms = <String>[
      l10n.packages_termsText1,
      l10n.packages_termsText2,
      l10n.packages_termsText3(package.rideCount),
    ];

    return PackageDetailSection(
      icon: Icons.gavel_rounded,
      title: l10n.packages_termsCancellation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, term) in terms.indexed) ...[
            if (index > 0) const SizedBox(height: ClientSpacing.sm),
            _Term(text: term),
          ],
        ],
      ),
    );
  }
}

/// Each clause on its own bulleted line — the block used to be one paragraph of
/// numbered sentences, which is the shape riders skip.
class _Term extends StatelessWidget {
  const _Term({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.textTertiaryFor(context),
            ),
          ),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }
}
