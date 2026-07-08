import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_route_arguments.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_flow_scaffold.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/popular_routes_body.dart';

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
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  context.read<BookingCubit>().loadPopularRoutes(force: true),
            ),
          ],
          body: PopularRoutesBody(
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
