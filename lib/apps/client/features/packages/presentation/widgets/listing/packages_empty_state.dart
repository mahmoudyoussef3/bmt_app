import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

/// The catalogue's empty state. The same shell serves three cases the listing
/// distinguishes — a marketplace with no packages at all, a selected office with
/// none, and a duration filter that matched nothing — each with its own copy and
/// (where useful) a way out.
class PackagesEmptyState extends StatelessWidget {
  const PackagesEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ClientSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ClientColors.textTertiaryFor(context)),
            const SizedBox(height: ClientSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ClientSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: ClientColors.textTertiaryFor(context),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ClientSpacing.md),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClientRadius.md),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
