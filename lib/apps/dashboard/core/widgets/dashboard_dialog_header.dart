import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

/// The one dialog header every Dashboard dialog converges on: an optional
/// round icon, a title, an optional one-line description, optional trailing
/// content (a status pill, a count), and a close button.
///
/// This is the header half of the console's dialog system — plain surface,
/// no gradient, no drop shadow, no tinted band. [icon] renders as a flat
/// [CircleAvatar] on `primaryContainer` (the same restrained treatment
/// already used by the route builder's stop editor), never a solid-fill
/// gradient badge. Pair with a [Divider] to close off the header the way
/// the trip pricing dialog does; omit it for a shorter dialog where the
/// header already reads as its own band (the stop editor's shape).
class DashboardDialogHeader extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onClose;

  const DashboardDialogHeader({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.medium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.medium),
            trailing!,
          ],
          if (onClose != null)
            IconButton(
              tooltip: 'إغلاق',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

/// The hairline rule between a dialog's header, content and action bands.
/// Same treatment everywhere it appears: a 1px [ColorScheme.outline] line at
/// a fixed low alpha, never a full-strength divider or a shadow standing in
/// for one.
class DashboardDialogDivider extends StatelessWidget {
  const DashboardDialogDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withAlpha(60),
    );
  }
}
