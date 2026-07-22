import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';

import '../../domain/entities/assigned_trip.dart';
import 'assigned_trip_card_parts.dart';

/// One of the day's remaining trips.
///
/// Laid out around a leading time rail — departure over arrival, joined by a
/// short track — which is how a timetable is read: the captain scans the column
/// of clock times for the one that is next, then reads across. The card used to
/// bury both times inside a row of small grey facts, so finding "the 13:00" in
/// a list meant reading every card in full.
///
/// It is also a plain surface: no outline. Six outlined-and-shadowed rectangles
/// down a page is a dashboard's widget grid; a phone list separates its rows
/// with space and a soft lift.
class AssignedTripCard extends StatelessWidget {
  const AssignedTripCard({
    super.key,
    required this.trip,
    required this.onOpen,
    required this.onManifest,
  });

  final AssignedTrip trip;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    final isDone = trip.status == AssignedTripStatus.completed;

    return CaptainTicker(
      builder: (context, now) {
        final stage = trip.stageAt(now);
        final accent = CaptainTripStagePalette.accent(stage);

        return Container(
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br20,
            boxShadow: CaptainDesignTokens.softShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            // A finished trip stays legible but stops competing with the ones
            // the captain still has to drive.
            opacity: isDone ? 0.72 : 1,
            child: Padding(
              padding: const EdgeInsets.all(CaptainDesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TimeRail(trip: trip, accent: accent),
                        const SizedBox(width: CaptainDesignTokens.s16),
                        Expanded(child: _Summary(trip: trip)),
                      ],
                    ),
                  ),
                  if (trip.passengerCount > 0) ...[
                    const SizedBox(height: CaptainDesignTokens.s16),
                    _BoardingBar(trip: trip, accent: accent),
                  ],
                  const SizedBox(height: CaptainDesignTokens.s16),
                  _Actions(
                    isDone: isDone,
                    openLabel: CaptainTripStageLabels.openAction(stage),
                    isRunning: trip.status.isRunning,
                    onOpen: onOpen,
                    onManifest: onManifest,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Departure over arrival, joined by a track — the timetable column a captain
/// scans down to find the trip they are looking for.
class _TimeRail extends StatelessWidget {
  const _TimeRail({required this.trip, required this.accent});

  final AssignedTrip trip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Spread to the rail's full height so each time sits beside its own
        // marker on the track, the way a timetable pairs them.
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CaptainFormats.clock(trip.departureTime),
              style: CaptainTypography.titleMedium(context).copyWith(
                fontWeight: FontWeight.w900,
                color: CaptainColors.textPrimaryFor(context),
                height: 1.1,
              ),
            ),
            Text(
              CaptainFormats.clock(trip.expectedArrivalTime),
              style: CaptainTypography.labelMedium(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        _Track(accent: accent),
      ],
    );
  }
}

/// The dot–line–ring that ties the two clock times together.
class _Track extends StatelessWidget {
  const _Track({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final line = CaptainColors.dividerFor(context);

    return Column(
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
        Expanded(child: Container(width: 2, color: line)),
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: line, width: 2),
          ),
        ),
      ],
    );
  }
}

/// The route and its status — everything that isn't a time.
class _Summary extends StatelessWidget {
  const _Summary({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                trip.route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: CaptainColors.textPrimaryFor(context),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            TripStatusBadge(status: trip.status),
          ],
        ),
        const SizedBox(height: 6),
        TripFact(
          icon: Icons.directions_bus_rounded,
          text: trip.vehicleNumber.isEmpty
              ? 'مركبة غير محددة'
              : trip.vehicleNumber,
        ),
      ],
    );
  }
}

class _BoardingBar extends StatelessWidget {
  const _BoardingBar({required this.trip, required this.accent});

  final AssignedTrip trip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = trip.passengerCount == 0
        ? 0.0
        : trip.boardedCount / trip.passengerCount;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: CaptainDesignTokens.brPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Text(
          '${trip.boardedCount}/${trip.passengerCount} صعدوا',
          style: CaptainTypography.labelMedium(context).copyWith(
            color: CaptainColors.textSecondaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isDone,
    required this.openLabel,
    required this.isRunning,
    required this.onOpen,
    required this.onManifest,
  });

  final bool isDone;

  /// Named for the stage the trip is actually in, so a card for an unreleased
  /// trip stops promising "بدء الرحلة".
  final String openLabel;
  final bool isRunning;
  final VoidCallback onOpen;
  final VoidCallback onManifest;

  @override
  Widget build(BuildContext context) {
    // A completed trip has nothing left to drive — only its manifest is useful.
    if (isDone) {
      return CaptainButton(
        label: 'كشف الركاب',
        icon: Icons.group_rounded,
        onPressed: onManifest,
        variant: CaptainButtonVariant.outline,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CaptainButton(
            label: openLabel,
            icon: isRunning
                ? Icons.play_arrow_rounded
                : Icons.info_outline_rounded,
            onPressed: onOpen,
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: CaptainButton(
            label: 'الركاب',
            icon: Icons.group_rounded,
            onPressed: onManifest,
            variant: CaptainButtonVariant.outline,
          ),
        ),
      ],
    );
  }
}
