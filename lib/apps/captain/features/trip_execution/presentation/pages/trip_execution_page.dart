import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_connectivity_banner.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_state.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/widgets/station_progress_section.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';
import '../widgets/trip_execution_action_bar.dart';
import '../widgets/trip_execution_canopy.dart';
import '../widgets/trip_execution_tools.dart';
import '../widgets/trip_gps_status_card.dart';

/// The captain's trip screen.
///
/// There is deliberately no map here. A captain driving a fixed route does not
/// navigate — they work a sequence of stations — and a map is a second thing
/// competing for the attention of someone holding a wheel. GPS itself is
/// untouched: [TripLocationAutoShare] keeps publishing throughout, because the
/// riders still waiting down the route are watching it.
class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripExecutionCubit>(
          create: (_) => captainGetIt<TripExecutionCubit>()
            ..watch(
              tripId: trip.id,
              routePointCount: trip.stops.length,
              initialSnapshot: _initialSnapshotFromTrip(trip),
            ),
        ),
        BlocProvider<StationProgressCubit>(
          create: (_) => captainGetIt<StationProgressCubit>()..watch(trip.id),
        ),
      ],
      child: _TripExecutionView(trip: trip),
    );
  }

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
    final stage = snapshot.status.stageAt(
      departureTime: trip.departureTime,
      now: now,
    );

    // GPS publishing follows the *trip*, never any one rider's boarding state:
    // the moment the vehicle is collecting passengers it starts, and it does not
    // stop until the trip ends. Who is allowed to read those positions is a
    // separate question, answered per booking by `can_read_trip_fixes`.
    final isSharingLocation = stage.isLive;

    return Scaffold(
      backgroundColor: CaptainColors.backgroundFor(context),
      body: CustomScrollView(
        slivers: [
          TripExecutionCanopy(trip: trip, snapshot: snapshot, stage: stage),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s24,
              CaptainDesignTokens.s20,
              CaptainDesignTokens.s32,
            ),
            sliver: SliverList.list(
              children: [
                const CaptainConnectivityBanner(),
                if (state case TripExecutionError(:final message)) ...[
                  _InlineError(message: message),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                TripLocationAutoShare(
                  tripId: trip.id,
                  enabled: isSharingLocation,
                ),
                if (stage.isLive) ...[
                  BlocBuilder<StationProgressCubit, StationProgressState>(
                    builder: (context, stationState) => StationProgressSection(
                      state: stationState,
                      now: now,
                    ),
                  ),
                  const SizedBox(height: CaptainDesignTokens.s24),
                  const CaptainSectionLabel('الموقع والوصول'),
                  TripGpsStatusCard(
                    lastLocation: snapshot.lastLocation,
                    destination: trip.stops.isEmpty ? null : trip.stops.last,
                    expectedArrivalTime: trip.expectedArrivalTime,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                const CaptainSectionLabel('أدوات الرحلة'),
                TripExecutionTools(tripId: trip.id, stage: stage),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TripExecutionActionBar(
        stage: stage,
        state: state,
        tripId: trip.id,
        departureTime: trip.departureTime,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.error.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: CaptainColors.error),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              message,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
