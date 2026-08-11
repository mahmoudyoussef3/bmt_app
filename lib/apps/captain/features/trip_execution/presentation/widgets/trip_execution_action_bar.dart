import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_state.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/widgets/station_primary_action.dart';

import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';
import 'trip_execution_primary_action.dart';
import 'trip_execution_sos_button.dart';

/// The docked action bar.
///
/// Once the trip is live the primary action comes from the *station* flow rather
/// than the trip status. That is the substance of "the captain cannot bypass
/// station progression": there is no longer a button that moves the trip from
/// boarding to in-progress on its own. Departing the first station is what
/// starts the trip, and departing it is gated.
class TripExecutionActionBar extends StatelessWidget {
  const TripExecutionActionBar({
    super.key,
    required this.stage,
    required this.state,
    required this.tripId,
    required this.departureTime,
  });

  final CaptainTripStage stage;
  final TripExecutionCubitState state;
  final String tripId;
  final DateTime departureTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        border: Border(
          top: BorderSide(color: CaptainColors.dividerFor(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(CaptainDesignTokens.s16),
          child: state is TripExecutionLoading
              ? const _Busy()
              : Row(
                  children: [
                    if (stage == CaptainTripStage.underway) ...[
                      TripExecutionSosButton(tripId: tripId),
                      const SizedBox(width: CaptainDesignTokens.s12),
                    ],
                    Expanded(child: _primaryAction(context)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _primaryAction(BuildContext context) {
    if (!stage.isLive) {
      return TripExecutionPrimaryAction(
        status: state.snapshot.status,
        tripId: tripId,
        departureTime: departureTime,
      );
    }

    return CaptainTicker(
      // Once a second while a countdown is on screen: the difference between
      // "you may leave at 08:45" and a live button is a minute the captain
      // should not have to guess at.
      interval: const Duration(seconds: 1),
      builder: (context, now) =>
          BlocBuilder<StationProgressCubit, StationProgressState>(
            builder: (context, stationState) => StationPrimaryAction(
              action: resolveStationAction(stationState.board, now),
              state: stationState,
              now: now,
              onComplete: () =>
                  context.read<TripExecutionCubit>().complete(tripId),
            ),
          ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: dockedActionHeight(context),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
