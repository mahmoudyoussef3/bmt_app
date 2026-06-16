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
import 'package:bmt_app/core/widgets/widgets.dart';

/// Full list of routes for quick client discovery.
class PopularRoutesScreen extends StatefulWidget {
  const PopularRoutesScreen({super.key});

  @override
  State<PopularRoutesScreen> createState() => _PopularRoutesScreenState();
}

class _PopularRoutesScreenState extends State<PopularRoutesScreen> {
  late BookingSearchQuery _query;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
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
            onRetry: context.read<BookingCubit>().loadPopularRoutes,
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
  RangeValues? _priceRange;
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
                sort: _sort,
                onSearchChanged: (value) => setState(() => _query = value),
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                onFilterTap: () => _openFilters(routes),
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
                    'Try a different departure, destination, duration, or price range.',
                actionLabel: 'Clear filters',
                onAction: _clearControls,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 292,
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
      _priceRange,
    ].where((value) => value != null).length;
  }

  List<PopularRouteListData> _applyControls(List<PopularRouteListData> routes) {
    final query = _query.trim().toLowerCase();
    final range = _priceRange;

    final filtered = routes.where((route) {
      final matchesQuery =
          query.isEmpty ||
          route.routeName.toLowerCase().contains(query) ||
          route.pickup.toLowerCase().contains(query) ||
          route.destination.toLowerCase().contains(query);
      final matchesDeparture = _departure == null || route.pickup == _departure;
      final matchesDestination =
          _destination == null || route.destination == _destination;
      final price = _priceValue(route.startingPrice);
      final matchesPrice =
          range == null ||
          (price != null && price >= range.start && price <= range.end);
      final matchesDuration = _matchesDuration(route.averageDuration);

      return matchesQuery &&
          matchesDeparture &&
          matchesDestination &&
          matchesPrice &&
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
      _priceRange = null;
      _duration = _DurationFilter.any;
      _sort = _RouteSort.recommended;
    });
  }

  Future<void> _openFilters(List<PopularRouteListData> routes) async {
    final prices = routes
        .map((route) => _priceValue(route.startingPrice))
        .whereType<int>()
        .toList();
    final maxPrice = prices.isEmpty
        ? 1000.0
        : prices.reduce((a, b) => a > b ? a : b).toDouble();
    final minPrice = prices.isEmpty
        ? 0.0
        : prices.reduce((a, b) => a < b ? a : b).toDouble();
    final departures = routes.map((route) => route.pickup).toSet().toList()
      ..sort();
    final destinations =
        routes.map((route) => route.destination).toSet().toList()..sort();

    final result = await showModalBottomSheet<_RouteFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _RouteFilterSheet(
          departures: departures,
          destinations: destinations,
          selectedDeparture: _departure,
          selectedDestination: _destination,
          selectedDuration: _duration,
          selectedPriceRange: _priceRange ?? RangeValues(minPrice, maxPrice),
          minPrice: minPrice,
          maxPrice: maxPrice <= minPrice ? minPrice + 1 : maxPrice,
        );
      },
    );

    if (result == null) return;
    setState(() {
      _departure = result.departure;
      _destination = result.destination;
      _duration = result.duration;
      _priceRange = result.priceRange;
    });
  }
}

class _RoutesDiscoveryHeader extends StatelessWidget {
  const _RoutesDiscoveryHeader({
    required this.controller,
    required this.query,
    required this.totalRoutes,
    required this.visibleRoutes,
    required this.activeFilters,
    required this.sort,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final String query;
  final int totalRoutes;
  final int visibleRoutes;
  final int activeFilters;
  final _RouteSort sort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final ValueChanged<_RouteSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Find your route fast',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          totalRoutes == 0
              ? 'Search active routes when they become available.'
              : '$visibleRoutes of $totalRoutes routes available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withAlpha(155),
            fontWeight: FontWeight.w600,
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  activeFilters == 0 ? 'Filters' : 'Filters ($activeFilters)',
                ),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<_RouteSort>(
              initialValue: sort,
              tooltip: 'Sort routes',
              onSelected: onSortChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _RouteSort.recommended,
                  child: Text('Recommended'),
                ),
                PopupMenuItem(
                  value: _RouteSort.priceLow,
                  child: Text('Lowest price'),
                ),
                PopupMenuItem(
                  value: _RouteSort.durationShort,
                  child: Text('Shortest duration'),
                ),
                PopupMenuItem(
                  value: _RouteSort.tripsHigh,
                  child: Text('Most trips'),
                ),
              ],
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline.withAlpha(110)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(_sortLabel(sort)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RouteFilterSheet extends StatefulWidget {
  const _RouteFilterSheet({
    required this.departures,
    required this.destinations,
    required this.selectedDeparture,
    required this.selectedDestination,
    required this.selectedDuration,
    required this.selectedPriceRange,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<String> departures;
  final List<String> destinations;
  final String? selectedDeparture;
  final String? selectedDestination;
  final _DurationFilter selectedDuration;
  final RangeValues selectedPriceRange;
  final double minPrice;
  final double maxPrice;

  @override
  State<_RouteFilterSheet> createState() => _RouteFilterSheetState();
}

class _RouteFilterSheetState extends State<_RouteFilterSheet> {
  late String? _departure = widget.selectedDeparture;
  late String? _destination = widget.selectedDestination;
  late _DurationFilter _duration = widget.selectedDuration;
  late RangeValues _priceRange = widget.selectedPriceRange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            'Filter routes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _ChoiceSection(
            title: 'Departure',
            values: widget.departures,
            selected: _departure,
            onSelected: (value) => setState(() => _departure = value),
          ),
          const SizedBox(height: 18),
          _ChoiceSection(
            title: 'Destination',
            values: widget.destinations,
            selected: _destination,
            onSelected: (value) => setState(() => _destination = value),
          ),
          const SizedBox(height: 18),
          Text(
            'Duration',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DurationFilter.values.map((value) {
              return FilterChip(
                selected: _duration == value,
                label: Text(_durationLabel(value)),
                onSelected: (_) => setState(() => _duration = value),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Price range',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${_priceRange.start.round()} - ${_priceRange.end.round()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(150),
              fontWeight: FontWeight.w700,
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: widget.minPrice,
            max: widget.maxPrice,
            divisions: 20,
            labels: RangeLabels(
              _priceRange.start.round().toString(),
              _priceRange.end.round().toString(),
            ),
            onChanged: (value) => setState(() => _priceRange = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const _RouteFilterResult(duration: _DurationFilter.any),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _RouteFilterResult(
                        departure: _departure,
                        destination: _destination,
                        duration: _duration,
                        priceRange: _priceRange,
                      ),
                    );
                  },
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: selected == null,
              label: const Text('Any'),
              onSelected: (_) => onSelected(null),
            ),
            ...values.where((value) => value.isNotEmpty).map((value) {
              return FilterChip(
                selected: selected == value,
                label: Text(value),
                onSelected: (_) => onSelected(value),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _RouteFilterResult {
  const _RouteFilterResult({
    this.departure,
    this.destination,
    this.duration = _DurationFilter.any,
    this.priceRange,
  });

  final String? departure;
  final String? destination;
  final _DurationFilter duration;
  final RangeValues? priceRange;
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
              const SkeletonBox(height: 30, width: 220),
              const SizedBox(height: 10),
              const SkeletonBox(height: 18, width: 280),
              const SizedBox(height: 16),
              SkeletonBox(height: 54, borderRadius: BorderRadius.circular(16)),
              const SizedBox(height: 12),
              SkeletonBox(height: 48, borderRadius: BorderRadius.circular(12)),
            ],
          );
        }
        return SkeletonBox(
          height: 292,
          borderRadius: BorderRadius.circular(18),
        );
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
