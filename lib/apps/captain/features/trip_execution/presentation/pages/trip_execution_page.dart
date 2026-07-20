import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_connectivity_banner.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';
import '../widgets/navigate_to_stop_button.dart';
import '../widgets/route_progress_timeline.dart';
import '../widgets/trip_execution_actions_grid.dart';
import '../widgets/trip_execution_header_card.dart';
import '../widgets/trip_execution_next_stop_banner.dart';
import '../widgets/trip_execution_sos_button.dart';
import '../widgets/trip_gps_status_card.dart';

class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripExecutionCubit>(
      create: (_) => captainGetIt<TripExecutionCubit>()
        ..watch(
          tripId: trip.id,
          routePointCount: trip.stops.length,
          initialSnapshot: _initialSnapshotFromTrip(trip),
        ),
      child: _TripExecutionView(trip: trip),
    );
  }

  /// Seeds the screen from the trip the captain tapped, so it never opens
  /// blank while the live watch connects.
  TripExecutionSnapshot _initialSnapshotFromTrip(AssignedTrip trip) {
    return TripExecutionSnapshot(
      status: switch (trip.status) {
        AssignedTripStatus.scheduled => TripExecutionStatus.scheduled,
        AssignedTripStatus.openForBooking => TripExecutionStatus.openForBooking,
        AssignedTripStatus.boarding => TripExecutionStatus.boarding,
        AssignedTripStatus.inProgress => TripExecutionStatus.inProgress,
        AssignedTripStatus.completed => TripExecutionStatus.completed,
      },
      passengerCount: trip.passengerCount,
      boardedCount: trip.boardedCount,
      arrivedStationsCount: trip.arrivedStationsCount,
    );
  }
}

class _TripExecutionView extends StatelessWidget {
  const _TripExecutionView({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return CaptainTicker(
      builder: (context, now) =>
          BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
            builder: (context, state) => _buildScaffold(context, state, now),
          ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    TripExecutionCubitState state,
    DateTime now,
  ) {
    final snapshot = state.snapshot;
    final isUnderway = snapshot.status == TripExecutionStatus.inProgress;
    final stage = snapshot.status.stageAt(
      departureTime: trip.departureTime,
      now: now,
    );

    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      floatingActionButton: isUnderway
          ? TripExecutionSosButton(tripId: trip.id)
          : null,
      body: CustomScrollView(
        slivers: [
          const CaptainSliverHeader(title: 'تنفيذ الرحلة'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                CaptainDesignTokens.s24,
                CaptainDesignTokens.s16,
                CaptainDesignTokens.s24,
                CaptainDesignTokens.s32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CaptainConnectivityBanner(),
                  TripExecutionHeaderCard(
                    trip: trip,
                    snapshot: snapshot,
                    state: state,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  // Kept mounted across the whole trip so the transition into
                  // and out of `inProgress` is an explicit start/stop rather
                  // than a widget disposal the timer happens to ride on.
                  TripLocationAutoShare(tripId: trip.id, enabled: isUnderway),
                  if (isUnderway && trip.stops.isNotEmpty)
                    _UnderwaySection(trip: trip, snapshot: snapshot),
                  Text(
                    'إجراءات الرحلة',
                    style: CaptainTypography.titleLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                  TripExecutionActionsGrid(tripId: trip.id, stage: stage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The live-navigation block: only meaningful once the trip is actually
/// underway and there is a route to run.
class _UnderwaySection extends StatelessWidget {
  const _UnderwaySection({required this.trip, required this.snapshot});

  final AssignedTrip trip;
  final TripExecutionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripExecutionNextStopBanner(
          tripId: trip.id,
          stops: trip.stops,
          arrivedStationsCount: snapshot.arrivedStationsCount,
        ),
        const SizedBox(height: CaptainDesignTokens.s24),
        RouteProgressTimeline(
          stops: trip.stops,
          arrivedStationsCount: snapshot.arrivedStationsCount,
        ),
        const SizedBox(height: CaptainDesignTokens.s24),
        TripGpsStatusCard(
          lastLocation: snapshot.lastLocation,
          destination: trip.stops.last,
          expectedArrivalTime: trip.expectedArrivalTime,
        ),
        const SizedBox(height: CaptainDesignTokens.s16),
        NavigateToStopButton(stop: _nextStop),
        const SizedBox(height: CaptainDesignTokens.s24),
      ],
    );
  }

  /// The next stop the captain hasn't reported arrived yet, or null once
  /// every station on the route has been reported (nothing left to
  /// navigate to).
  AssignedTripStop? get _nextStop {
    final index = snapshot.arrivedStationsCount;
    if (index >= trip.stops.length) return null;
    return trip.stops[index];
  }
}
