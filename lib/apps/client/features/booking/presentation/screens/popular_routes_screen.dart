import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/popular_route_list_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Full list of routes for quick client discovery.
class PopularRoutesScreen extends StatefulWidget {
  const PopularRoutesScreen({super.key});

  @override
  State<PopularRoutesScreen> createState() => _PopularRoutesScreenState();
}

class _PopularRoutesScreenState extends State<PopularRoutesScreen> {
  late BookingSearchQuery _query;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
    if (_didLoad) return;
    _didLoad = true;
    context.read<BookingCubit>().loadPopularRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        return BookingFlowScaffold(
          title: 'Routes',
          query: _query.isComplete ? _query : null,
          body: _PopularRoutesBody(
            state: state,
            onRetry: () =>
                context.read<BookingCubit>().loadPopularRoutes(force: true),
            onRouteTap: (route) {
              final updated = _query.copyWith(
                routeId: route.id,
                pickup: route.pickup,
                destination: route.destination,
              );
              Navigator.pushNamed(
                context,
                BookingRoutes.routeSelection,
                arguments: updated.toArguments(),
              );
            },
          ),
        );
      },
    );
  }
}

enum _RouteSort { recommended, priceLow, durationShort, tripsHigh }

enum _DurationFilter { any, underOneHour, oneToTwoHours, overTwoHours }

class _PopularRoutesBody extends StatefulWidget {
  const _PopularRoutesBody({
    required this.state,
    required this.onRetry,
    required this.onRouteTap,
  });

  final BookingState state;
  final VoidCallback onRetry;
  final void Function(PopularRouteListData route) onRouteTap;

  @override
  State<_PopularRoutesBody> createState() => _PopularRoutesBodyState();
}

class _PopularRoutesBodyState extends State<_PopularRoutesBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _departure;
  String? _destination;
  _DurationFilter _duration = _DurationFilter.any;
  _RouteSort _sort = _RouteSort.recommended;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is BookingLoading) {
      return const _RoutesLoadingSkeleton();
    }
    if (widget.state is BookingError) {
      return _BookingErrorState(
        message: (widget.state as BookingError).message,
        onRetry: widget.onRetry,
      );
    }

    final routes = widget.state is PopularRoutesLoaded
        ? (widget.state as PopularRoutesLoaded).routes
        : <PopularRouteListData>[];
    final filteredRoutes = _applyControls(routes);
    final activeFilters = _activeFilterCount;
    final isTablet = MediaQuery.sizeOf(context).width >= 720;
    final departures = _uniqueValues(routes.map((route) => route.pickup));
    final destinations = _uniqueValues(
      routes.map((route) => route.destination),
    );

    return RefreshIndicator(
      onRefresh: () async => widget.onRetry(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _RoutesDiscoveryHeader(
                controller: _searchController,
                query: _query,
                totalRoutes: routes.length,
                visibleRoutes: filteredRoutes.length,
                activeFilters: activeFilters,
                departures: departures,
                destinations: destinations,
                selectedDeparture: _departure,
                selectedDestination: _destination,
                selectedDuration: _duration,
                sort: _sort,
                onSearchChanged: (value) => setState(() => _query = value),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                onDepartureChanged: (value) =>
                    setState(() => _departure = value),
                onDestinationChanged: (value) =>
                    setState(() => _destination = value),
                onDurationChanged: (value) => setState(() => _duration = value),
                onClearFilters: _clearFilters,
                onSortChanged: (sort) => setState(() => _sort = sort),
              ),
            ),
          ),
          if (routes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _RoutesEmptyState(
                title: 'No active routes yet',
                subtitle:
                    'Routes published from the dashboard will appear here when they are ready for booking.',
                actionLabel: 'Refresh routes',
                onAction: widget.onRetry,
              ),
            )
          else if (filteredRoutes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _RoutesEmptyState(
                title: 'No routes match your search',
                subtitle:
                    'Try a different departure, destination, or duration.',
                actionLabel: 'Clear filters',
                onAction: _clearControls,
              ),
            )
          else
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
                    onTap: () => widget.onRouteTap(route),
                  );
                }, childCount: filteredRoutes.length),
              ),
            ),
        ],
      ),
    );
  }

  int get _activeFilterCount {
    return [
      _departure,
      _destination,
      _duration == _DurationFilter.any ? null : _duration,
    ].where((value) => value != null).length;
  }

  List<PopularRouteListData> _applyControls(List<PopularRouteListData> routes) {
    final query = _query.trim().toLowerCase();

    final filtered = routes.where((route) {
      final matchesQuery =
          query.isEmpty ||
          route.routeName.toLowerCase().contains(query) ||
          route.pickup.toLowerCase().contains(query) ||
          route.destination.toLowerCase().contains(query);
      final matchesDeparture = _departure == null || route.pickup == _departure;
      final matchesDestination =
          _destination == null || route.destination == _destination;
      final matchesDuration = _matchesDuration(route.averageDuration);

      return matchesQuery &&
          matchesDeparture &&
          matchesDestination &&
          matchesDuration;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _RouteSort.recommended => b.dailyTrips.compareTo(a.dailyTrips),
        _RouteSort.priceLow =>
          (_priceValue(a.startingPrice) ?? 1 << 30).compareTo(
            _priceValue(b.startingPrice) ?? 1 << 30,
          ),
        _RouteSort.durationShort =>
          (_durationMinutes(a.averageDuration) ?? 1 << 30).compareTo(
            _durationMinutes(b.averageDuration) ?? 1 << 30,
          ),
        _RouteSort.tripsHigh => b.dailyTrips.compareTo(a.dailyTrips),
      };
    });

    return filtered;
  }

  bool _matchesDuration(String value) {
    if (_duration == _DurationFilter.any) return true;
    final minutes = _durationMinutes(value);
    if (minutes == null) return true;

    return switch (_duration) {
      _DurationFilter.any => true,
      _DurationFilter.underOneHour => minutes < 60,
      _DurationFilter.oneToTwoHours => minutes >= 60 && minutes <= 120,
      _DurationFilter.overTwoHours => minutes > 120,
    };
  }

  void _clearControls() {
    _searchController.clear();
    setState(() {
      _query = '';
      _departure = null;
      _destination = null;
      _duration = _DurationFilter.any;
      _sort = _RouteSort.recommended;
    });
  }

  void _clearFilters() {
    setState(() {
      _departure = null;
      _destination = null;
      _duration = _DurationFilter.any;
    });
  }

  List<String> _uniqueValues(Iterable<String> values) {
    return values.where((value) => value.trim().isNotEmpty).toSet().toList()
      ..sort();
  }
}

class _RoutesDiscoveryHeader extends StatelessWidget {
  const _RoutesDiscoveryHeader({
    required this.controller,
    required this.query,
    required this.totalRoutes,
    required this.visibleRoutes,
    required this.activeFilters,
    required this.departures,
    required this.destinations,
    required this.selectedDeparture,
    required this.selectedDestination,
    required this.selectedDuration,
    required this.sort,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onDepartureChanged,
    required this.onDestinationChanged,
    required this.onDurationChanged,
    required this.onClearFilters,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final String query;
  final int totalRoutes;
  final int visibleRoutes;
  final int activeFilters;
  final List<String> departures;
  final List<String> destinations;
  final String? selectedDeparture;
  final String? selectedDestination;
  final _DurationFilter selectedDuration;
  final _RouteSort sort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onDepartureChanged;
  final ValueChanged<String?> onDestinationChanged;
  final ValueChanged<_DurationFilter> onDurationChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<_RouteSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withAlpha(45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find your best commute',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          totalRoutes == 0
                              ? 'Search active routes when they become available.'
                              : '$visibleRoutes of $totalRoutes routes match your search',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withAlpha(165),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withAlpha(45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: scheme.onPrimary,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderMetricChip(
                    icon: Icons.route_outlined,
                    label: '$totalRoutes total',
                  ),
                  _HeaderMetricChip(
                    icon: Icons.filter_alt_outlined,
                    label: activeFilters == 0
                        ? 'No filters'
                        : '$activeFilters filters',
                  ),
                  _HeaderMetricChip(
                    icon: Icons.sort_rounded,
                    label: _sortLabel(sort),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search departure, destination, or route name',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClearSearch,
                  ),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withAlpha(75)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withAlpha(75)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _SortMenuButton(sort: sort, onSelected: onSortChanged),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _LocationFilterMenu(
                icon: Icons.trip_origin_rounded,
                label: 'Departure',
                values: departures,
                selected: selectedDeparture,
                anyLabel: 'Any departure',
                onSelected: onDepartureChanged,
              ),
              const SizedBox(width: 8),
              _LocationFilterMenu(
                icon: Icons.place_rounded,
                label: 'Destination',
                values: destinations,
                selected: selectedDestination,
                anyLabel: 'Any destination',
                onSelected: onDestinationChanged,
              ),
              const SizedBox(width: 8),
              _DurationFilterMenu(
                selected: selectedDuration,
                onSelected: onDurationChanged,
              ),
              if (activeFilters > 0) ...[
                const SizedBox(width: 8),
                _ClearFiltersChip(
                  activeFilters: activeFilters,
                  onPressed: onClearFilters,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _HeaderMetricChip extends StatelessWidget {
  const _HeaderMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(210),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({required this.sort, required this.onSelected});

  final _RouteSort sort;
  final ValueChanged<_RouteSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_RouteSort>(
      initialValue: sort,
      tooltip: 'Sort routes',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _RouteSort.recommended,
          child: Text('Recommended'),
        ),
        PopupMenuItem(value: _RouteSort.priceLow, child: Text('Lowest price')),
        PopupMenuItem(
          value: _RouteSort.durationShort,
          child: Text('Shortest duration'),
        ),
        PopupMenuItem(value: _RouteSort.tripsHigh, child: Text('Most trips')),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withAlpha(95)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              _sortLabel(sort),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LocationFilterMenu extends StatelessWidget {
  const _LocationFilterMenu({
    required this.icon,
    required this.label,
    required this.values,
    required this.selected,
    required this.anyLabel,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final List<String> values;
  final String? selected;
  final String anyLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: selected,
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: _PopupMenuText(text: anyLabel),
        ),
        ...values.map(
          (value) => PopupMenuItem<String?>(
            value: value,
            child: _PopupMenuText(text: value),
          ),
        ),
      ],
      child: _FilterPill(
        icon: icon,
        label: label,
        value: selected ?? 'Any',
        isActive: selected != null,
      ),
    );
  }
}

class _DurationFilterMenu extends StatelessWidget {
  const _DurationFilterMenu({required this.selected, required this.onSelected});

  final _DurationFilter selected;
  final ValueChanged<_DurationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DurationFilter>(
      initialValue: selected,
      tooltip: 'Duration',
      onSelected: onSelected,
      itemBuilder: (context) => _DurationFilter.values
          .map(
            (value) => PopupMenuItem<_DurationFilter>(
              value: value,
              child: Text(_durationLabel(value)),
            ),
          )
          .toList(),
      child: _FilterPill(
        icon: Icons.schedule_rounded,
        label: 'Duration',
        value: _durationLabel(selected),
        isActive: selected != _DurationFilter.any,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isActive ? scheme.primary.withAlpha(18) : scheme.surface;
    final borderColor = isActive
        ? scheme.primary.withAlpha(130)
        : scheme.outline.withAlpha(85);

    return Container(
      height: 56,
      constraints: const BoxConstraints(minWidth: 126, maxWidth: 236),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: isActive ? scheme.primary : null),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withAlpha(145),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive ? scheme.primary : scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurface.withAlpha(150),
          ),
        ],
      ),
    );
  }
}

class _ClearFiltersChip extends StatelessWidget {
  const _ClearFiltersChip({
    required this.activeFilters,
    required this.onPressed,
  });

  final int activeFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, size: 18),
        label: Text('Clear $activeFilters'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _PopupMenuText extends StatelessWidget {
  const _PopupMenuText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _RoutesLoadingSkeleton extends StatelessWidget {
  const _RoutesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClientSkeleton(height: 30, width: 220),
              const SizedBox(height: 10),
              const ClientSkeleton(height: 18, width: 280),
              const SizedBox(height: 16),
              ClientSkeleton(height: 54, borderRadius: 16),
              const SizedBox(height: 12),
              ClientSkeleton(height: 48, borderRadius: 12),
            ],
          );
        }
        return ClientSkeleton(height: 292, borderRadius: 18);
      },
    );
  }
}

class _RoutesEmptyState extends StatelessWidget {
  const _RoutesEmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.route_outlined,
                color: scheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withAlpha(155),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _BookingErrorState extends StatelessWidget {
  const _BookingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _sortLabel(_RouteSort sort) {
  return switch (sort) {
    _RouteSort.recommended => 'Recommended',
    _RouteSort.priceLow => 'Price',
    _RouteSort.durationShort => 'Duration',
    _RouteSort.tripsHigh => 'Trips',
  };
}

String _durationLabel(_DurationFilter filter) {
  return switch (filter) {
    _DurationFilter.any => 'Any',
    _DurationFilter.underOneHour => 'Under 1h',
    _DurationFilter.oneToTwoHours => '1-2h',
    _DurationFilter.overTwoHours => '2h+',
  };
}

int? _priceValue(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

int? _durationMinutes(String value) {
  final lower = value.toLowerCase();
  final number = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower)?.group(1);
  if (number == null) return null;
  final parsed = double.tryParse(number);
  if (parsed == null) return null;
  if (lower.contains('hour') || lower.contains('hr') || lower.contains('h')) {
    return (parsed * 60).round();
  }
  return parsed.round();
}
