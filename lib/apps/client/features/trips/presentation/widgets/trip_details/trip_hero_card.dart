import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_chips.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_fact_strip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_journey.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_schedule_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';

/// Trip Details' hero: status, reference, the pickup → drop-off rail, and the
/// date/departure/seat strip.
///
/// It carries the whole journey, so the screen no longer repeats pickup and
/// destination again in a separate Route section further down.
class TripHeroCard extends StatelessWidget {
  const TripHeroCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final badge = ClientColors.journeyBadgeFor(
      context,
      journeyStatusFor(trip.status),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ClientColors.heroTopFor(context).withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const PositionedDirectional(top: -70, end: -50, child: _HeroGlow()),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeroStatusChip(
                        label: trip.statusLabel,
                        color: badge.label,
                      ),
                      const SizedBox(width: 12),
                      // Expanded + Align, not Spacer + Flexible: a Spacer would
                      // claim half the free space and ellipsize a reference
                      // that had room to fit.
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: HeroReferenceChip(reference: trip.reference),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  HeroJourney(
                    pickup: trip.pickup,
                    destination: trip.destination,
                    departureLabel: tripTimeLabel(context, trip),
                  ),
                  const SizedBox(height: 22),
                  HeroFactStrip(
                    facts: [
                      HeroFact(
                        icon: Icons.calendar_today_rounded,
                        label: 'DATE',
                        value: tripDayLabel(context, trip),
                      ),
                      HeroFact(
                        icon: Icons.schedule_rounded,
                        label: 'DEPARTS',
                        value: tripTimeLabel(context, trip),
                      ),
                      HeroFact(
                        icon: Icons.event_seat_rounded,
                        label: _seatsLabel(trip),
                        value: _seatsValue(trip),
                      ),
                    ],
                  ),
                  if (trip.completedAt != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Completed ${trip.completedAt}',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: Colors.white.withAlpha(200)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seatsLabel(TripData trip) =>
      trip.mySeatLabels.length > 1 ? 'SEATS' : 'SEAT';

  String _seatsValue(TripData trip) {
    final seats = trip.mySeatLabels;
    if (seats.isEmpty) return 'Not assigned';
    return seats.join(', ');
  }
}

/// A soft off-canvas light source — calmer than the oversized bus glyph the
/// hero used to stamp across its corner.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withAlpha(46), Colors.white.withAlpha(0)],
        ),
      ),
    );
  }
}
