import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/popular_route_list_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_results_empty_state.dart';

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
  if (routes.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: RouteResultsEmptyState(
          title: 'No active routes yet',
          subtitle:
              'Routes published from the dashboard will appear here when they are ready for booking.',
          actionLabel: 'Refresh routes',
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
          title: 'No routes match your search',
          subtitle: 'Try a different search term or adjust your filters.',
          actionLabel: 'Reset filters',
          onAction: onResetFilters,
        ),
      ),
    ];
  }
  final isTablet = MediaQuery.sizeOf(context).width >= 720;
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 116),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 304,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final route = filteredRoutes[index];
          return PopularRouteListCard(
            route: route,
            onTap: () => onRouteTap(route),
          );
        }, childCount: filteredRoutes.length),
      ),
    ),
  ];
}
