import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/popular_routes_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/popular_routes_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/popular_routes_body.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Full list of routes for quick client discovery.
class PopularRoutesScreen extends StatelessWidget {
  const PopularRoutesScreen({super.key, required this.query});

  final BookingSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PopularRoutesCubit>();
    return BlocBuilder<PopularRoutesCubit, PopularRoutesState>(
      builder: (context, state) {
        return BookingFlowScaffold(
          title: context.l10n.nav_routes,
          query: query.isComplete ? query : null,
          actions: [
            IconButton(
              tooltip: context.l10n.tracking_refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: cubit.load,
            ),
          ],
          body: PopularRoutesBody(
            isLoading: state is PopularRoutesLoading,
            errorMessage: state is PopularRoutesError ? state.message : null,
            routes: state is PopularRoutesLoaded
                ? state.routes
                : const <PopularRouteListData>[],
            onRetry: cubit.load,
            onRouteTap: (route) => _openRoute(context, route),
          ),
        );
      },
    );
  }

  void _openRoute(BuildContext context, PopularRouteListData route) {
    final updated = query.copyWith(
      routeId: route.id,
      pickup: route.pickup,
      destination: route.destination,
    );
    Navigator.pushNamed(
      context,
      BookingRoutes.routeSelection,
      arguments: updated.toArguments(),
    );
  }
}
