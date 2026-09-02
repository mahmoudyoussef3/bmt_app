import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
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

    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.medium,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: DashboardColors.divider(context)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DashboardSectionGlyph(icon: icon),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: child,
          ),
        ],
      ),
    );
  }
}
