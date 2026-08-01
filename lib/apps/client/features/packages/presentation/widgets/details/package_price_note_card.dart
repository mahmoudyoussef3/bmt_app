import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Answers the first question a rider has about a plan — "what does it cost?" —
/// in the only way that is true: it depends on the route.
///
/// A package is priced per corridor, so the catalogue holds no single number
/// worth showing. Saying nothing would read as a missing field; this says the
/// price exists, explains what it hangs on, and points at the step that
/// produces it.
class PackagePriceNoteCard extends StatelessWidget {
  const PackagePriceNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const accent = ClientColors.journeyAmber;

    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: accent.withAlpha(20),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sell_outlined, size: 20, color: accent),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.packages_priceDependsTitle,
                  style: ClientTypography.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.packages_priceDependsBody,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
