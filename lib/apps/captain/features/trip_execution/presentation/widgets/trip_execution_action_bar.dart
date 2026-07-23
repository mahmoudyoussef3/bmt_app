import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';

import '../cubit/trip_execution_state.dart';
import 'trip_execution_primary_action.dart';
import 'trip_execution_sos_button.dart';

/// The trip's one action, docked to the bottom of the screen.
///
/// It used to sit inside the header card, roughly a third of the way down a
/// page that also carried a next-stop banner, a route timeline, a GPS panel and
/// an action grid — so "بدء الرحلة" and "إنهاء الرحلة" were reached by
/// scrolling, by a captain who is at the wheel. Docking it puts the only
/// control that matters permanently in the thumb zone, which is where a phone
/// app puts a primary action.
///
/// The emergency call sits beside it while the trip is running, for the same
/// reason: an SOS that is reachable only after a scroll is not an SOS. It
/// replaced a floating action button, which the docked bar would have covered.
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

/// A transition is in flight. Sized to the bar's resting height so committing
/// an action doesn't make the page jump under the captain's thumb — including
/// at an enlarged system font, where that height is taller than 56.
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
