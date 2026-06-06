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

/// Full list of popular / most-used routes.
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
          title: 'Popular Routes',
          query: _query.isComplete ? _query : null,
          body: _PopularRoutesBody(
            state: state,
            onRetry: context.read<BookingCubit>().loadPopularRoutes,
            onRouteTap: (route) {
              final updated = _query.copyWith(
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

class _PopularRoutesBody extends StatelessWidget {
  const _PopularRoutesBody({
    required this.state,
    required this.onRetry,
    required this.onRouteTap,
  });

  final BookingState state;
  final VoidCallback onRetry;
  final void Function(PopularRouteListData route) onRouteTap;

  @override
  Widget build(BuildContext context) {
    if (state is BookingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is BookingError) {
      return _BookingErrorState(
        message: (state as BookingError).message,
        onRetry: onRetry,
      );
    }
    final routes = state is PopularRoutesLoaded
        ? (state as PopularRoutesLoaded).routes
        : const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(
          title: 'Most used routes',
          subtitle: 'Frequently booked commutes across the network',
        ),
        const SizedBox(height: 12),
        ...routes.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PopularRouteListCard(
              route: route,
              onTap: () => onRouteTap(route),
            ),
          );
        }),
      ],
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
