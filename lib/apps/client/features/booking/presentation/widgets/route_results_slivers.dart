import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/popular_route_list_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_results_empty_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Builds the sliver(s) for the discovery grid's data section: the
/// no-routes-at-all empty state, the no-match empty state, or the result
/// grid — never a blank list (spec FR-012).
List<Widget> routeResultsSlivers({
  required BuildContext context,
  required List<PopularRouteListData> routes,
  required List<PopularRouteListData> filteredRoutes,
  required VoidCallback onRetry,
  required VoidCallback onResetFilters,
  required ValueChanged<PopularRouteListData> onRouteTap,
}) {
  final l10n = context.l10n;
  if (routes.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: RouteResultsEmptyState(
          title: l10n.booking_noActiveRoutesYet,
          subtitle: l10n.booking_routesFromDashboardAppear,
          actionLabel: l10n.booking_refreshRoutes,
          onAction: onRetry,
        ),
      ),
    ];
  }
  if (filteredRoutes.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: RouteResultsEmptyState(
          title: l10n.booking_noRoutesMatchSearch,
          subtitle: l10n.booking_tryDifferentSearchTerm,
          actionLabel: l10n.booking_resetFilters,
          onAction: onResetFilters,
        ),
      ),
    ];
  }
  final isTablet = MediaQuery.sizeOf(context).width >= 720;
  final crossAxisCount = isTablet ? 2 : 1;

  final rows = <List<PopularRouteListData>>[
    for (var i = 0; i < filteredRoutes.length; i += crossAxisCount)
      filteredRoutes.skip(i).take(crossAxisCount).toList(),
  ];

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 116),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final rowRoutes = rows[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == rows.length - 1 ? 0 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < rowRoutes.length; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: PopularRouteListCard(
                      route: rowRoutes[j],
                      onTap: () => onRouteTap(rowRoutes[j]),
                    ),
                  ),
                ],
                if (rowRoutes.length < crossAxisCount) const Spacer(),
              ],
            ),
          );
        }, childCount: rows.length),
      ),
    ),
  ];
}
