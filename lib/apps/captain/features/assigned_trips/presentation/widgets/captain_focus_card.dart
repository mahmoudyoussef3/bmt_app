import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/assigned_trip.dart';
import 'assigned_trip_card_parts.dart';
import 'captain_focus_card_parts.dart';
import 'home_quick_actions.dart';

class CaptainFocusCard extends StatelessWidget {
  const CaptainFocusCard({super.key, required this.trip, required this.onOpen});

  final AssignedTrip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return CaptainTicker(
      builder: (context, now) {
        final stage = trip.stageAt(now);
        final accent = CaptainTripStagePalette.accent(stage);

        return Container(
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br24,
            border: CaptainDesignTokens.hairline(context),
            // The only shadow on the home screen, and it is brand-tinted: this
            // is the trip the captain is on, lifted off the day's other cards.
            boxShadow: CaptainDesignTokens.glow(context, accent, alpha: 0.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusEyebrow(
                isRunning: stage.isLive,
                label: CaptainTripStageLabels.eyebrow(stage),
                accent: accent,
                trailing: FocusCrownNote(
                  text: assignedTripStatusLabel(trip.status),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CaptainTypography.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: CaptainColors.textPrimaryFor(context),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FocusFact(
                          icon: Icons.schedule_rounded,
                          text:
                              'الانطلاق ${CaptainFormats.clock(trip.departureTime)}',
                        ),
                        const SizedBox(width: CaptainDesignTokens.s16),
                        FocusFact(
                          icon: Icons.directions_bus_rounded,
                          text: trip.vehicleNumber.isEmpty
                              ? 'مركبة غير محددة'
                              : trip.vehicleNumber,
                        ),
                      ],
                    ),
                    if (trip.passengerCount > 0) ...[
                      const SizedBox(height: CaptainDesignTokens.s16),
                      FocusBoardingBar(
                        boarded: trip.boardedCount,
                        total: trip.passengerCount,
                        accent: accent,
                      ),
                    ],
                    const SizedBox(height: CaptainDesignTokens.s12),
                    FocusStatusPanel(
                      text: CaptainTripStageLabels.status(
                        stage: stage,
                        departureTime: trip.departureTime,
                        now: now,
                      ),
                      icon: CaptainTripStagePalette.icon(stage),
                      accent: accent,
                    ),
                    const SizedBox(height: CaptainDesignTokens.s16),
                    FocusAction(
                      label: CaptainTripStageLabels.openAction(stage),
                      icon: _actionIcon(stage),
                      accent: accent,
                      onPressed: onOpen,
                    ),
                  ],
                ),
              ),
              const CaptainRowDivider(indent: 0),
              HomeQuickActions(tripId: trip.id, stage: stage),
            ],
          ),
        );
      },
    );
  }

  IconData _actionIcon(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway => Icons.play_circle_fill_rounded,
    CaptainTripStage.boarding ||
    CaptainTripStage.readyToBoard => Icons.people_alt_rounded,
    _ => Icons.info_outline_rounded,
  };
}
