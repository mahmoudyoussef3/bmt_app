import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/assigned_trip.dart';
import 'captain_focus_card_parts.dart';

/// The one thing the captain should act on now: the running trip, or the next
/// scheduled one. Deliberately the loudest element on the home screen.
///
/// Everything time-dependent here is rebuilt from a [CaptainTicker] rather
/// than sampled once at build: the home cubit only re-emits on realtime trip
/// changes, so a countdown drawn from a build-time `DateTime.now()` froze at
/// whatever gap existed when the screen loaded.
class CaptainFocusCard extends StatelessWidget {
  const CaptainFocusCard({super.key, required this.trip, required this.onOpen});

  final AssignedTrip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return CaptainTicker(
      builder: (context, now) {
        final stage = trip.stageAt(now);

        return Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CaptainColors.primary,
                CaptainColors.primary.withValues(alpha: 0.85),
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: CaptainDesignTokens.br24,
            boxShadow: [
              BoxShadow(
                color: CaptainColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusEyebrow(
                isRunning: stage.isLive,
                label: CaptainTripStageLabels.eyebrow(stage),
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              Text(
                trip.route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.titleLarge(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              Row(
                children: [
                  // The scheduled departure is stated as a clock time, always.
                  // A relative countdown alone gives the captain nothing to
                  // check against the trip's own schedule.
                  FocusFact(
                    icon: Icons.schedule_rounded,
                    text:
                        'الانطلاق ${CaptainFormats.clock(trip.departureTime)}',
                  ),
                  const SizedBox(width: CaptainDesignTokens.s16),
                  FocusFact(
                    icon: Icons.people_alt_rounded,
                    text: '${trip.boardedCount}/${trip.passengerCount} راكب',
                  ),
                ],
              ),
              const SizedBox(height: CaptainDesignTokens.s16),
              FocusStatusPill(
                text: CaptainTripStageLabels.status(
                  stage: stage,
                  departureTime: trip.departureTime,
                  now: now,
                ),
                icon: _stageIcon(stage),
              ),
              const SizedBox(height: CaptainDesignTokens.s20),
              FocusAction(
                label: CaptainTripStageLabels.openAction(stage),
                icon: _actionIcon(stage),
                onPressed: onOpen,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _stageIcon(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.awaitingRelease => Icons.lock_clock_rounded,
    CaptainTripStage.awaitingWindow => Icons.hourglass_top_rounded,
    CaptainTripStage.readyToBoard => Icons.how_to_reg_rounded,
    CaptainTripStage.boarding => Icons.people_alt_rounded,
    CaptainTripStage.underway => Icons.directions_bus_filled_rounded,
    CaptainTripStage.finished => Icons.check_circle_rounded,
    CaptainTripStage.cancelled => Icons.cancel_rounded,
  };

  IconData _actionIcon(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway => Icons.play_circle_fill_rounded,
    CaptainTripStage.boarding ||
    CaptainTripStage.readyToBoard => Icons.people_alt_rounded,
    _ => Icons.info_outline_rounded,
  };
}
