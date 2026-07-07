import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/apply_route_filters.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/active_filters_row.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_results_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_results_slivers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/routes_discovery_header.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/show_route_filter_sheet.dart';

/// The routes discovery/results content: search + filters header, active
/// filters, and the result grid, sized to whichever [BookingState] arrives.
class PopularRoutesBody extends StatefulWidget {
  const PopularRoutesBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRouteTap,
  });

  final BookingState state;
  final VoidCallback onRetry;
  final void Function(PopularRouteListData route) onRouteTap;

  @override
  State<PopularRoutesBody> createState() => _PopularRoutesBodyState();
}

class _PopularRoutesBodyState extends State<PopularRoutesBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  RouteFilterCriteria _criteria = const RouteFilterCriteria();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is BookingLoading) return const RouteResultsSkeleton();
    if (widget.state is BookingError) {
      return ClientErrorCard.fullScreen(
        message: (widget.state as BookingError).message,
        onRetry: widget.onRetry,
      );
    }

    final routes = widget.state is PopularRoutesLoaded
        ? (widget.state as PopularRoutesLoaded).routes
        : <PopularRouteListData>[];
    final filteredRoutes = applyRouteFilters(routes, _criteria, _query);

    return RefreshIndicator(
      onRefresh: () async => widget.onRetry(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RoutesDiscoveryHeader(
                    controller: _searchController,
                    totalRoutes: routes.length,
                    visibleRoutes: filteredRoutes.length,
                    activeFilters: _criteria.activeCount,
                    onSearchChanged: (value) => setState(() => _query = value),
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    onOpenFilters: () => _openFilters(routes),
                  ),
                  ActiveFiltersRow(
                    criteria: _criteria,
                    onChanged: (updated) => setState(() => _criteria = updated),
                    onResetAll: () =>
                        setState(() => _criteria = _criteria.reset()),
                  ),
                ],
              ),
            ),
          ),
          ...routeResultsSlivers(
            context: context,
            routes: routes,
            filteredRoutes: filteredRoutes,
            onRetry: widget.onRetry,
            onResetFilters: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _criteria = _criteria.reset();
              });
            },
            onRouteTap: widget.onRouteTap,
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(List<PopularRouteListData> routes) async {
    final result = await showRouteFilterSheet(
      context: context,
      routes: routes,
      criteria: _criteria,
    );
    if (result != null) setState(() => _criteria = result);
  }
}
