import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_labels.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage_palette.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_text_direction.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';

import '../../domain/entities/trip_execution_state.dart';

/// What this trip is and where it stands, as a full-bleed header painted in the
/// trip's own stage colour.
///
/// This replaces a white card that sat under a plain "تنفيذ الرحلة" toolbar and
/// carried the route, a status chip, two tinted fact boxes and the primary
/// action all at once. Three problems with that: the screen's title named the
/// screen rather than the trip, the card was one more framed rectangle in a
/// column of them, and the action a driving captain most needs was buried
/// mid-scroll (it now lives in a docked bar at the bottom of the page).
///
/// The gradient is the stage — slate while operations still owns the trip,
/// brand blue once it is the captain's to board, amber through boarding, and
/// the bright live end of the palette while it is actually moving. A captain
/// glancing down at a cradled phone reads the state from the colour before
/// reading a word.
class TripExecutionCanopy extends StatelessWidget {
  const TripExecutionCanopy({
    super.key,
    required this.trip,
    required this.snapshot,
    required this.stage,
  });

  final AssignedTrip trip;
  final TripExecutionSnapshot snapshot;
  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: CaptainTripStagePalette.gradient(stage),
            borderRadius: const BorderRadius.only(
              bottomLeft: CaptainDesignTokens.r32,
              bottomRight: CaptainDesignTokens.r32,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CaptainDesignTokens.s20,
                CaptainDesignTokens.s8,
                CaptainDesignTokens.s20,
                CaptainDesignTokens.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _BackButton(),
                      const Spacer(),
                      // Flexible, not bare: at an enlarged system font the
                      // stage label grows past the width the back button
                      // leaves it, and a fixed chip overflows the canopy.
                      // Shrinking the chip keeps the row intact.
                      Flexible(child: _StageChip(stage: stage)),
                    ],
                  ),
                  const SizedBox(height: CaptainDesignTokens.s16),
                  Text(
                    trip.route,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CaptainTypography.headlineSmall(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: CaptainDesignTokens.s8),
                  _VehicleLine(trip: trip),
                  const SizedBox(height: CaptainDesignTokens.s20),
                  _Facts(trip: trip, snapshot: snapshot),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.closeScreen(),
        child: const SizedBox(
          width: 40,
          height: 40,
          // `arrow_back` ships with `matchTextDirection`, so Flutter mirrors it
          // to point rightwards in this RTL layout on its own. Reaching for
          // `arrow_forward` to "pre-mirror" it flips it twice and lands back on
          // an arrow pointing the wrong way.
          child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// The stage, named. The canopy already says it in colour; this says it in
/// words for anyone who does not read the colour that way.
class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});

  final CaptainTripStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s4,
        CaptainDesignTokens.s12,
        CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(46),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: Colors.white.withAlpha(56)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CaptainTripStagePalette.icon(stage),
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: CaptainDesignTokens.s4),
          // The chip shrinks before the row breaks; the stage name then
          // truncates rather than pushing the back button off the canopy.
          Flexible(
            child: Text(
              CaptainTripStageLabels.eyebrow(stage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelMedium(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bus the captain is looking for, and its plate.
class _VehicleLine extends StatelessWidget {
  const _VehicleLine({required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    final style = CaptainTypography.bodyMedium(
      context,
    ).copyWith(color: Colors.white.withAlpha(215), fontWeight: FontWeight.w700);

    return Row(
      children: [
        Icon(
          Icons.directions_bus_rounded,
          size: 16,
          color: Colors.white.withAlpha(200),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            trip.vehicleNumber.isEmpty ? 'مركبة غير محددة' : trip.vehicleNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (trip.plateNumber.isNotEmpty) ...[
          Text(' · ', style: style),
          Flexible(
            // The plate resolves its own direction: this fleet runs Egyptian
            // plates but latin ones turn up too, and either reorders if handed
            // the screen's direction instead of its own.
            child: Directionality(
              textDirection: CaptainTextDirection.ofIdentifier(
                trip.plateNumber,
              ),
              child: Text(
                trip.plateNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The three numbers the trip is judged by, as glass tiles on the gradient.
class _Facts extends StatelessWidget {
  const _Facts({required this.trip, required this.snapshot});

  final AssignedTrip trip;
  final TripExecutionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final stops = trip.stops.length;

    return Row(
      children: [
        _Fact(
          icon: Icons.schedule_rounded,
          value: CaptainFormats.timeRange(
            trip.departureTime,
            trip.expectedArrivalTime,
          ),
          label: 'التوقيت',
        ),
        const SizedBox(width: CaptainDesignTokens.s8),
        _Fact(
          icon: Icons.people_alt_rounded,
          value: '${snapshot.boardedCount}/${snapshot.passengerCount}',
          label: 'صعدوا',
        ),
        if (stops > 0) ...[
          const SizedBox(width: CaptainDesignTokens.s8),
          _Fact(
            icon: Icons.location_on_rounded,
            value: '${snapshot.arrivedStationsCount.clamp(0, stops)}/$stops',
            label: 'المحطات',
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s8,
          vertical: CaptainDesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(36),
          borderRadius: CaptainDesignTokens.br16,
          border: Border.all(color: Colors.white.withAlpha(46)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: Colors.white.withAlpha(200)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: CaptainTypography.titleSmall(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.labelSmall(context).copyWith(
                color: Colors.white.withAlpha(205),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
