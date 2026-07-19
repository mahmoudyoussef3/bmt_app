import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown when a filter matches no package — previously the catalogue just went
/// blank with no explanation.
class PackagesEmptyState extends StatelessWidget {
  const PackagesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(height: ClientSpacing.sm),
            Text(
              context.l10n.packages_emptyTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ClientSpacing.xs),
            Text(
              context.l10n.packages_emptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: ClientColors.textTertiaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
