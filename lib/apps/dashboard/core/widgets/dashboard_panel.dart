import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Titled content card used for analytics panels, tables and detail sections.
/// One header style (icon + title + optional subtitle + optional trailing)
/// shared across the dashboard.
///
/// Pass a [sectionId] to make the panel collapsible. It then renders as a
/// [DashboardCollapsibleSection] — same header, plus a chevron and session
/// memory — which is why modules never build their own collapse behaviour: the
/// panel they already use grows it with one argument.
class DashboardPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  /// Stable key from [DashboardSectionIds]. Non-null turns the panel into a
  /// collapsible section whose state survives module switches.
  final String? sectionId;

  /// Shown in place of [child] while collapsed. Only meaningful with a
  /// [sectionId].
  final Widget? collapsedSummary;

  /// State the first time this section is seen in a session. Ignored once the
  /// operator has made their own choice.
  final bool initiallyExpanded;

  const DashboardPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.sectionId,
    this.collapsedSummary,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sectionId != null) {
      return DashboardCollapsibleSection(
        sectionId: sectionId,
        icon: icon,
        title: title,
        subtitle: subtitle,
        actions: [?trailing],
        initiallyExpanded: initiallyExpanded,
        collapsedSummary: collapsedSummary,
        child: child,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}
