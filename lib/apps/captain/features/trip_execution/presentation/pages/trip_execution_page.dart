import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_connectivity_banner.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';
import '../widgets/navigate_to_stop_button.dart';
import '../widgets/route_progress_timeline.dart';
import '../widgets/trip_execution_action_bar.dart';
import '../widgets/trip_execution_canopy.dart';
import '../widgets/trip_execution_next_stop_banner.dart';
import '../widgets/trip_execution_tools.dart';
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

/// The trip, as a stage-coloured canopy over a scrolling body, with the one
/// action that matters docked at the bottom.
///
/// The action used to live inside a card a third of the way down this page,
/// under the route and above a timeline, a GPS panel and a grid of square
/// tiles — a layout that asks a captain at the wheel to scroll before they can
/// start or end a trip. Everything below the canopy is now reference material
/// the captain reads at a stop; everything they *do* is in the docked bar.
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
                // The live map is the trip's primary operational surface once
                // it is running: the captain's position, the route, and the
                // pickup sequence. Offered from boarding onward; the map itself
                // reads the device GPS locally and adds no database traffic.
                if (stage.isLive) ...[
                  _LiveMapCta(trip: trip),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                // Kept mounted across the whole trip so the transition into
                // and out of `inProgress` is an explicit start/stop rather
                // than a widget disposal the timer happens to ride on.
                TripLocationAutoShare(tripId: trip.id, enabled: isUnderway),
                if (isUnderway && trip.stops.isNotEmpty) ...[
                  const CaptainSectionLabel('المحطة القادمة'),
                  TripExecutionNextStopBanner(
                    tripId: trip.id,
                    stops: trip.stops,
                    arrivedStationsCount: snapshot.arrivedStationsCount,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                  NavigateToStopButton(stop: _nextStop(snapshot)),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                // The route is worth showing before departure too: a captain
                // checking which stops they are due to call at should not have
                // to start the trip to find out.
                if (trip.stops.isNotEmpty) ...[
                  const CaptainSectionLabel('مسار الرحلة'),
                  RouteProgressTimeline(
                    stops: trip.stops,
                    arrivedStationsCount: snapshot.arrivedStationsCount,
                  ),
                  const SizedBox(height: CaptainDesignTokens.s24),
                ],
                if (isUnderway) ...[
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

  /// The next stop the captain hasn't reported arrived yet, or null once
  /// every station on the route has been reported (nothing left to
  /// navigate to).
  AssignedTripStop? _nextStop(TripExecutionSnapshot snapshot) {
    final index = snapshot.arrivedStationsCount;
    if (index >= trip.stops.length) return null;
    return trip.stops[index];
  }
}

/// The entry point to the live trip map — the trip's primary operational
/// surface while it is running. A hero card rather than a tools-list row: the
/// map is where the captain reads their position and works the pickups.
class _LiveMapCta extends StatelessWidget {
  const _LiveMapCta({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.openTripMap(trip),
      borderRadius: CaptainDesignTokens.br24,
      child: Container(
        padding: const EdgeInsets.all(CaptainDesignTokens.s20),
        decoration: BoxDecoration(
          gradient: CaptainColors.primaryGradient(context),
          borderRadius: CaptainDesignTokens.br24,
          boxShadow: CaptainDesignTokens.floatingShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: CaptainDesignTokens.br16,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الخريطة المباشرة',
                    style: CaptainTypography.titleMedium(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'موقعك، المسار، ونقطة التجميع القادمة',
                    style: CaptainTypography.bodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
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
