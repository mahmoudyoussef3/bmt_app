import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Unified frame for tabular data: an [AppCard] with a consistent
/// icon + title + trailing-count header and a full-bleed [child] body
/// (e.g. a horizontally-scrollable `DataTable`). Gives every data table the
/// same shell across the dashboard.
class DashboardTableFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget child;

  const DashboardTableFrame({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary, size: 20),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outline.withAlpha(40)),
          child,
        ],
      ),
    );
  }
}
