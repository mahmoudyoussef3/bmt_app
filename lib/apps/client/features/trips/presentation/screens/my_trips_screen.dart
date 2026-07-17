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

/// My Trips hub with filter tabs for upcoming, active, completed, cancelled.
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  TripFilter _filter = TripFilter.upcoming;

  @override
  void initState() {
    super.initState();
    context.read<TripsCubit>().loadTrips();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 900 ? 720.0 : (width >= 600 ? 560.0 : width);

    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<TripsCubit, TripsState>(
          builder: (context, state) {
            final cubit = context.read<TripsCubit>();
            final allTrips = state is TripsLoaded ? state.trips : <TripData>[];
            final trips = cubit.tripsForFilter(_filter, allTrips);
            final counts = {
              for (final filter in TripFilter.values)
                filter: cubit.countForFilter(filter, allTrips),
            };

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: RefreshIndicator(
                  onRefresh: () => context.read<TripsCubit>().loadTrips(),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: TripsHeader(
                            upcomingCount: counts[TripFilter.upcoming] ?? 0,
                            activeCount: counts[TripFilter.active] ?? 0,
                            onBookTrip: () =>
                                widget.onOpenRoute(BookingRoutes.search),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TripFilterBar(
                            selected: _filter,
                            counts: counts,
                            onSelected: (filter) =>
                                setState(() => _filter = filter),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TripsSectionTitle(
                            filter: _filter,
                            count: trips.length,
                          ),
                        ),
                      ),
                      ...tripListContentSlivers(
                        state: state,
                        filter: _filter,
                        trips: trips,
                        onRetry: context.read<TripsCubit>().loadTrips,
                        onBrowseRoutes: () =>
                            widget.onOpenRoute(BookingRoutes.search),
                        onOpenTrip: (trip) => widget.onOpenRoute(
                          TripsRoutes.tripDetails,
                          {'tripId': trip.id},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
