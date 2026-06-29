import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Route details and decision screen for the current search.
class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  late BookingSearchQuery _query;
  String? _selectedRouteId;
  String? _selectedTripId;
  String? _loadedQueryKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _query = bookingQueryFromContext(context);
    final queryKey = _queryKey(_query);
    if (_loadedQueryKey == queryKey) return;
    _loadedQueryKey = queryKey;
    context.read<BookingCubit>().loadRoutes(_query);
  }

  void _continueToVehicles() {
    final routeId = _selectedRouteId;
    if (routeId == null || routeId.isEmpty) return;
    final arguments = _query.copyWith(routeId: routeId).toArguments();
    final tripId = _selectedTripId;
    if (tripId != null) arguments['tripId'] = tripId;
    Navigator.pushNamed(
      context,
      ClientRoutes.bookingVehicleListing,
      arguments: arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final routes = state is BookingRoutesLoaded
            ? state.routes
            : <RouteOptionData>[];
        if (routes.isNotEmpty) {
          final queryRouteId = _query.routeId;
          _selectedRouteId ??=
              queryRouteId != null &&
                  routes.any((route) => route.id == queryRouteId)
              ? queryRouteId
              : routes.first.id;
        }
        final selectedRoute = _selectedRoute(routes);

        return BookingFlowScaffold(
          title: 'Route details',
          query: _query,
          bottomBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ClientButton(
                label: selectedRoute == null
                    ? 'Select route'
                    : 'Continue with this route',
                expand: true,
                onPressed: selectedRoute == null ? null : _continueToVehicles,
              ),
            ),
          ),
          body: _RouteDetailsBody(
            state: state,
            routes: routes,
            selectedRoute: selectedRoute,
            selectedTripId: _selectedTripId,
            onRetry: () =>
                context.read<BookingCubit>().loadRoutes(_query, force: true),
            onMap: () {
              Navigator.pushNamed(
                context,
                ClientRoutes.bookingMapSelection,
                arguments: _query.toArguments(),
              );
            },
            onSelectRoute: (route) {
              Navigator.pushNamed(
                context,
                ClientRoutes.bookingRouteOverview,
                arguments: route,
              );
            },
            onSelectTrip: (trip) => setState(() => _selectedTripId = trip.id),
          ),
        );
      },
    );
  }

  RouteOptionData? _selectedRoute(List<RouteOptionData> routes) {
    if (routes.isEmpty) return null;
    return routes.firstWhere(
      (route) => route.id == _selectedRouteId,
      orElse: () => routes.first,
    );
  }

  String _queryKey(BookingSearchQuery query) {
    return [
      query.routeId ?? '',
      query.pickup,
      query.destination,
      query.date,
      query.time,
    ].join('|');
  }
}

class _RouteDetailsBody extends StatelessWidget {
  const _RouteDetailsBody({
    required this.state,
    required this.routes,
    required this.selectedRoute,
    required this.selectedTripId,
    required this.onRetry,
    required this.onMap,
    required this.onSelectRoute,
    required this.onSelectTrip,
  });

  final BookingState state;
  final List<RouteOptionData> routes;
  final RouteOptionData? selectedRoute;
  final String? selectedTripId;
  final VoidCallback onRetry;
  final VoidCallback onMap;
  final ValueChanged<RouteOptionData> onSelectRoute;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) return const _RouteDetailsLoading();
    if (state is BookingError) {
      return _BookingErrorState(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }
    final route = selectedRoute;
    if (route == null) {
      return _RouteEmptyState(onRetry: onRetry);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        if (!route.isExactMatch) ...[
          _ClosestMatchBanner(quality: route.matchQuality),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                route.isExactMatch
                    ? 'Is this route suitable?'
                    : 'Closest routes for your search',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onMap,
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Map'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RouteOverviewCard(route: route),
        const SizedBox(height: 14),
        _RouteTimelineCard(points: route.points),
        const SizedBox(height: 14),
        _PricingCard(route: route),
        const SizedBox(height: 14),
        _AvailableTripsSection(
          trips: route.availableTrips,
          hasRoutePricing: !_isPendingPrice(route.startingPrice),
          selectedTripId: selectedTripId,
          onSelectTrip: onSelectTrip,
        ),
        if (routes.length > 1) ...[
          const SizedBox(height: 18),
          _AlternativeRoutesSection(
            routes: routes,
            selectedRouteId: route.id,
            onSelectRoute: onSelectRoute,
          ),
        ],
      ],
    );
  }

  bool _isPendingPrice(String value) {
    return value.trim().toLowerCase() == 'price pending';
  }
}

class _ClosestMatchBanner extends StatelessWidget {
  const _ClosestMatchBanner({required this.quality});

  final RouteMatchQuality quality;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPartial = quality == RouteMatchQuality.partial;
    final message = isPartial
        ? 'No exact match for your search. These routes cover most of your trip.'
        : 'No route matches this exact trip yet. Here are the closest options we run.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: scheme.tertiary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best results for you',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteOverviewCard extends StatelessWidget {
  const _RouteOverviewCard({required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: ClientColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.pickup} to ${route.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OverviewMetric(
                icon: Icons.trip_origin_rounded,
                label: 'Departure',
                value: route.pickup,
              ),
              _OverviewMetric(
                icon: Icons.flag_rounded,
                label: 'Destination',
                value: route.destination,
              ),
              _OverviewMetric(
                icon: Icons.straighten_rounded,
                label: 'Distance',
                value: route.distance,
              ),
              _OverviewMetric(
                icon: Icons.schedule_rounded,
                label: 'Duration',
                value: route.duration,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withAlpha(135),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimelineCard extends StatelessWidget {
  const _RouteTimelineCard({required this.points});

  final List<RoutePointData> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final orderedPoints = [...points]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ClientColors.primaryContainerFor(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: ClientColors.primaryFor(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route timeline',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pickup and drop-off availability by stop',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _InlineEmpty(
                icon: Icons.alt_route_rounded,
                title: 'Stops are not published yet',
                subtitle: 'Route stations will appear here once available.',
              ),
            )
          else
            ...orderedPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return _TimelineStop(
                point: point,
                isFirst: index == 0,
                isLast: index == orderedPoints.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineStop extends StatelessWidget {
  const _TimelineStop({
    required this.point,
    required this.isFirst,
    required this.isLast,
  });

  final RoutePointData point;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isFirst
        ? ClientColors.journeyGreen
        : isLast
        ? ClientColors.primaryFor(context)
        : ClientColors.accent;
    final bgColor = isFirst
        ? ClientColors.journeyGreenLight
        : isLast
        ? ClientColors.primaryContainerFor(context)
        : ClientColors.journeyAmberLight;
    final roleLabel = isFirst
        ? 'Start'
        : isLast
        ? 'End'
        : 'Stop ${point.order}';

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, isLast ? 18 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(65),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFirst
                        ? Icons.trip_origin_rounded
                        : isLast
                        ? Icons.flag_rounded
                        : Icons.place_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withAlpha(95),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor.withAlpha(
                      Theme.of(context).brightness == Brightness.dark
                          ? 34
                          : 120,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(70)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              point.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StopRoleChip(label: roleLabel, color: color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (point.pickupAllowed)
                            const _CapabilityChip(
                              label: 'Pickup',
                              icon: Icons.login_rounded,
                              color: ClientColors.journeyGreen,
                            ),
                          if (point.dropoffAllowed)
                            const _CapabilityChip(
                              label: 'Drop-off',
                              icon: Icons.logout_rounded,
                              color: ClientColors.primary,
                            ),
                          if (!point.pickupAllowed && !point.dropoffAllowed)
                            _CapabilityChip(
                              label: 'Pass-through',
                              icon: Icons.route_rounded,
                              color: scheme.outline,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRoleChip extends StatelessWidget {
  const _StopRoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriceBlock(
              label: 'Starting price',
              value: route.startingPrice,
              highlighted: true,
            ),
          ),
          Container(width: 1, height: 48, color: scheme.outline.withAlpha(70)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _PriceBlock(label: 'Price range', value: route.priceRange),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurface.withAlpha(145),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: highlighted
              ? ClientTypography.priceMedium(context).copyWith(fontSize: 21)
              : Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _AvailableTripsSection extends StatelessWidget {
  const _AvailableTripsSection({
    required this.trips,
    required this.hasRoutePricing,
    required this.selectedTripId,
    required this.onSelectTrip,
  });

  final List<RouteTripOptionData> trips;
  final bool hasRoutePricing;
  final String? selectedTripId;
  final ValueChanged<RouteTripOptionData> onSelectTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available trips',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the departure that works best for you.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 14),
          if (trips.isEmpty)
            _InlineEmpty(
              icon: Icons.event_busy_rounded,
              title: hasRoutePricing
                  ? 'No bookable trips right now'
                  : 'No scheduled trips yet',
              subtitle: hasRoutePricing
                  ? 'This route has pricing, but no upcoming trip is open for booking.'
                  : 'Trips created from the dashboard will appear here.',
            )
          else
            ...trips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TripOptionTile(
                  trip: trip,
                  selected: selectedTripId == trip.id,
                  onTap: () => onSelectTrip(trip),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripOptionTile extends StatelessWidget {
  const _TripOptionTile({
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  final RouteTripOptionData trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withAlpha(18)
                : scheme.surfaceContainerHighest.withAlpha(45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline.withAlpha(45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.departureTime} - ${trip.arrivalTime}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.vehicleType} · ${trip.availableSeats} seats',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trip.price,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativeRoutesSection extends StatelessWidget {
  const _AlternativeRoutesSection({
    required this.routes,
    required this.selectedRouteId,
    required this.onSelectRoute,
  });

  final List<RouteOptionData> routes;
  final String selectedRouteId;
  final ValueChanged<RouteOptionData> onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final alternatives = routes
        .where((route) => route.id != selectedRouteId)
        .toList();
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other matching routes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...alternatives.map(
          (route) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelectRoute(route),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ClientColors.borderFor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.routeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ClientTypography.bodyMedium(
                                context,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${route.duration} · ${route.startingPrice}',
                              style: ClientTypography.bodySmall(context)
                                  .copyWith(
                                    color: ClientColors.textSecondaryFor(
                                      context,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: ClientColors.textTertiaryFor(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(145),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDetailsLoading extends StatelessWidget {
  const _RouteDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ClientSkeleton(height: 30, width: 220),
        const SizedBox(height: 14),
        ClientSkeleton(height: 176, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 220, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 100, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 190, borderRadius: 18),
      ],
    );
  }
}

class _RouteEmptyState extends StatelessWidget {
  const _RouteEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, color: scheme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'No bookable route found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different departure, destination, or travel time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
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
