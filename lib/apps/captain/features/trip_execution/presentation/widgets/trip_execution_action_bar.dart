import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

import '../cubit/trip_execution_state.dart';
import 'trip_execution_primary_action.dart';
import 'trip_execution_sos_button.dart';

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
                    Expanded(
                      child: TripExecutionPrimaryAction(
                        status: state.snapshot.status,
                        tripId: tripId,
                        departureTime: departureTime,
                      ),
                    ),
                  ],
                ),
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
