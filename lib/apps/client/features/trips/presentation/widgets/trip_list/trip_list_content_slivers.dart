import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_error_card.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trips_empty_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/trips_loading_skeleton.dart';

/// Builds the sliver(s) for the trip list's data section — loading skeleton,
/// error, tailored empty state, or the list itself — never a blank list.
List<Widget> tripListContentSlivers({
  required TripsState state,
  required TripFilter filter,
  required List<TripData> trips,
  required VoidCallback onRetry,
  required VoidCallback onBrowseRoutes,
  required ValueChanged<TripData> onOpenTrip,
}) {
  if (state is TripsLoading) {
    return const [
      SliverFillRemaining(hasScrollBody: false, child: TripsLoadingSkeleton()),
    ];
  }
  if (state is TripsError) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClientErrorCard.fullScreen(
            message: state.message,
            onRetry: onRetry,
          ),
        ),
      ),
    ];
  }
  if (trips.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: TripsEmptyState(filter: filter, onBrowseRoutes: onBrowseRoutes),
      ),
    ];
  }
  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final trip = trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TripCard(trip: trip, onTap: () => onOpenTrip(trip)),
          );
        }, childCount: trips.length),
      ),
    ),
  ];
}
