import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_filter_bar.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _TripsHeader(
                          upcomingCount: counts[TripFilter.upcoming] ?? 0,
                          activeCount: counts[TripFilter.active] ?? 0,
                          onBookTrip: () =>
                              widget.onOpenRoute(ClientRoutes.bookingSearch),
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
                        child: _SectionTitle(
                          filter: _filter,
                          count: trips.length,
                        ),
                      ),
                    ),
                    if (state is TripsLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _TripsLoadingSkeleton(),
                      )
                    else if (state is TripsError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _TripsErrorState(
                          message: state.message,
                          onRetry: context.read<TripsCubit>().loadTrips,
                        ),
                      )
                    else if (trips.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _TripsEmptyState(filter: _filter),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final trip = trips[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TripCard(
                                trip: trip,
                                onTap: () => widget.onOpenRoute(
                                  TripsRoutes.tripDetails,
                                  {'tripId': trip.id},
                                ),
                              ),
                            );
                          }, childCount: trips.length),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader({
    required this.upcomingCount,
    required this.activeCount,
    required this.onBookTrip,
  });

  final int upcomingCount;
  final int activeCount;
  final VoidCallback onBookTrip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Trips',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upcoming, active, and past commutes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(205),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: onBookTrip,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  tooltip: 'Book new trip',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Upcoming',
                    value: '$upcomingCount',
                    icon: Icons.upcoming_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Active',
                    value: '$activeCount',
                    icon: Icons.directions_bus_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.textInverse.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.textInverse.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ClientColors.textInverse),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textInverse),
              ),
              Text(
                value,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: ClientColors.textInverse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.filter, required this.count});

  final TripFilter filter;
  final int count;

  String get _title {
    switch (filter) {
      case TripFilter.upcoming:
        return 'Upcoming trips';
      case TripFilter.active:
        return 'In progress trips';
      case TripFilter.completed:
        return 'Completed trips';
      case TripFilter.cancelled:
        return 'Cancelled trips';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _title,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TripsEmptyState extends StatelessWidget {
  const _TripsEmptyState({required this.filter});

  final TripFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      TripFilter.upcoming => 'No upcoming trips scheduled',
      TripFilter.active => 'No trips in progress right now',
      TripFilter.completed => 'No completed trips yet',
      TripFilter.cancelled => 'No cancelled trips',
    };

    final subtitle = switch (filter) {
      TripFilter.upcoming => 'Book a trip to see it here',
      TripFilter.active => 'Your active trips will appear here',
      TripFilter.completed => 'Completed trips will appear here',
      TripFilter.cancelled => 'Cancelled trips will appear here',
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ClientTypography.headingSmall(context),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _TripsErrorState extends StatelessWidget {
  const _TripsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ClientErrorCard.fullScreen(message: message, onRetry: onRetry),
    );
  }
}

class _TripsLoadingSkeleton extends StatelessWidget {
  const _TripsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          ClientSkeleton.tripCard(),
          const SizedBox(height: 12),
          ClientSkeleton.tripCard(),
          const SizedBox(height: 12),
          ClientSkeleton.tripCard(),
        ],
      ),
    );
  }
}
