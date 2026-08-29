import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

/// The width below which a list drops from its table to the card layout.
///
/// One number for all of المبيعات. The three modules each picked their own —
/// 900, 1040, 1100 — so dragging the console narrower turned the section into
/// tables and cards in a staggered order, and the same window showed a table on
/// one tab and cards on the next. 1040 is the widest of the three column sets'
/// honest minimum: below it the eight-column bookings table starts scrolling
/// sideways, which is the point at which stacked cards read better.
const double kDashboardTableBreakpoint = 1040;

/// How many cards a list shows per row once it has dropped below
/// [kDashboardTableBreakpoint].
///
/// The two card layouts in المبيعات each had their own rule — one went to two
/// columns at 720px, the other at 940 — so between those widths the same window
/// showed the bookings queue two-up and the subscriber board one-up. A row of
/// cards carries a name, a route, a money block and a pair of actions; below
/// ~470px each that stops being readable, which is the number both rules were
/// reaching for.
int dashboardCardColumnsFor(double width) {
  if (width >= 1560) return 3;
  if (width >= 940) return 2;
  return 1;
}

/// The strip that introduces a list: what it is, how much of it you are
/// looking at, and the controls that act on the whole page of rows.
///
/// Sits between the filters and the rows in every المبيعات module. Before it,
/// each module answered "how many results" in a different place and shape — one
/// in a bare `Row`, one inside the board header beside a select-all, one not at
/// all — so the same question needed a different eye movement per tab.
class DashboardResultsHeader extends StatelessWidget {
  const DashboardResultsHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final IconData icon;

  /// What this list is: «قائمة المشتركين», «العملاء», the open queue's name.
  final String title;

  /// The range in view — "عرض ١–١٢ من ٤٥". Already formatted by the module.
  final String? subtitle;

  /// Controls acting on the whole page: select-all, ordering, an export.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = subtitle;

    final identity = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: DashboardColors.accentInk(context)),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
        ],
      ],
    );

    if (actions.isEmpty) return identity;

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        identity,
        Row(mainAxisSize: MainAxisSize.min, children: actions),
      ],
    );
  }
}
