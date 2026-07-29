import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_results_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_booking_action.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_details_body.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Route details and decision screen for the current search.
class RouteSelectionScreen extends StatelessWidget {
  const RouteSelectionScreen({super.key, required this.query});

  final BookingSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RouteResultsCubit>();
    return BlocBuilder<RouteResultsCubit, RouteResultsState>(
      builder: (context, state) {
        final loaded = state is RouteResultsLoaded ? state : null;
        return BookingFlowScaffold(
          title: context.l10n.booking_routeDetails,
          query: query,
          actions: [
            IconButton(
              tooltip: context.l10n.tracking_refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => cubit.load(query),
            ),
          ],
          bottomBar: RouteBookingAction(
            route: loaded?.selectedRoute,
            onContinue: (route) => _continueToBooking(context, route),
          ),
          body: RouteDetailsBody(
            isLoading: state is RouteResultsLoading,
            errorMessage: state is RouteResultsError ? state.message : null,
            routes: loaded?.routes ?? const <RouteOptionData>[],
            selectedRoute: loaded?.selectedRoute,
            selectedTripId: loaded?.selectedTripId,
            onRetry: () => cubit.load(query),
            onMap: () => Navigator.pushNamed(
              context,
              BookingRoutes.mapSelection,
              arguments: query.toArguments(),
            ),
            onSelectRoute: (route) => cubit.selectRoute(route.id),
            onSelectTrip: (trip) => cubit.selectTrip(trip.id),
          ),
        );
      },
    );
  }

  void _continueToBooking(BuildContext context, RouteOptionData route) {
    final initialPackageId = query.initialPackageId;
    Navigator.pushNamed(
      context,
      BookingRoutes.wizard,
      arguments: initialPackageId == null
          ? route
          : {'route': route, 'initialPackageId': initialPackageId},
    );
  }
}
