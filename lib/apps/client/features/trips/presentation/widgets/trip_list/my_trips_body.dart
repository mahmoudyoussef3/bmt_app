import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_filter_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trip_list_content_slivers.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trips_header.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trips_section_title.dart';

/// The pull-to-refresh scroll body of My Trips: header, filter tabs, section
/// title, and the state-driven content slivers, width-capped on tablets.
class MyTripsBody extends StatelessWidget {
  const MyTripsBody({
    super.key,
    required this.state,
    required this.filter,
    required this.trips,
    required this.counts,
    required this.onOpenRoute,
  });

  final TripsState state;
  final TripFilter filter;
  final List<TripData> trips;
  final Map<TripFilter, int> counts;
  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 900 ? 720.0 : (width >= 600 ? 560.0 : width);
    final cubit = context.read<TripsCubit>();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RefreshIndicator(
          onRefresh: cubit.loadTrips,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: TripsHeader(
                    upcomingCount: counts[TripFilter.upcoming] ?? 0,
                    activeCount: counts[TripFilter.active] ?? 0,
                    onBookTrip: () => onOpenRoute(BookingRoutes.search),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TripFilterBar(
                    selected: filter,
                    counts: counts,
                    onSelected: cubit.setFilter,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TripsSectionTitle(filter: filter, count: trips.length),
                ),
              ),
              ...tripListContentSlivers(
                state: state,
                filter: filter,
                trips: trips,
                onRetry: cubit.loadTrips,
                onBrowseRoutes: () => onOpenRoute(BookingRoutes.search),
                onOpenTrip: (trip) =>
                    onOpenRoute(TripsRoutes.tripDetails, {'tripId': trip.id}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
