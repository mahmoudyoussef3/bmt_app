import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_booking_action.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_body.dart';

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

  void _continueToBooking(RouteOptionData route) {
    Navigator.pushNamed(context, BookingRoutes.wizard, arguments: route);
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
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  context.read<BookingCubit>().loadRoutes(_query, force: true),
            ),
          ],
          bottomBar: RouteBookingAction(
            route: selectedRoute,
            onContinue: _continueToBooking,
          ),
          body: RouteDetailsBody(
            state: state,
            routes: routes,
            selectedRoute: selectedRoute,
            selectedTripId: _selectedTripId,
            onRetry: () =>
                context.read<BookingCubit>().loadRoutes(_query, force: true),
            onMap: () {
              Navigator.pushNamed(
                context,
                BookingRoutes.mapSelection,
                arguments: _query.toArguments(),
              );
            },
            onSelectRoute: (route) {
              setState(() {
                _selectedRouteId = route.id;
                _selectedTripId = null;
              });
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
