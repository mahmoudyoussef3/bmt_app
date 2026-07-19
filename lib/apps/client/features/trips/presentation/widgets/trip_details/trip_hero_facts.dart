import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/hero_fact_strip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_schedule_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The date / departure / seat facts shown under the hero's journey rail.
List<HeroFact> tripHeroFacts(BuildContext context, TripData trip) {
  return [
    HeroFact(
      icon: Icons.calendar_today_rounded,
      label: context.l10n.common_date.toUpperCase(),
      value: tripDayLabel(context, trip),
    ),
    HeroFact(
      icon: Icons.schedule_rounded,
      label: context.l10n.trips_factDeparts.toUpperCase(),
      value: tripTimeLabel(context, trip),
    ),
    HeroFact(
      icon: Icons.event_seat_rounded,
      label: _seatsLabel(context, trip),
      value: _seatsValue(context, trip),
    ),
  ];
}

String _seatsLabel(BuildContext context, TripData trip) =>
    (trip.mySeatLabels.length > 1
            ? context.l10n.common_seats
            : context.l10n.trips_factSeat)
        .toUpperCase();

String _seatsValue(BuildContext context, TripData trip) {
  final seats = trip.mySeatLabels;
  if (seats.isEmpty) return context.l10n.trips_seatNotAssigned;
  return seats.join(', ');
}
