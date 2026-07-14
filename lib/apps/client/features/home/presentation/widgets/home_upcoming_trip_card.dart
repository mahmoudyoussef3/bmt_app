import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_actions.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_card_header.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_facts.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_journey.dart';

/// One bookable departure, laid out as a boarding pass so a rider reads it in
/// the order they decide in:
///
/// 1. the tinted band — when it leaves and which route it runs
/// 2. the journey — where it picks them up and drops them off
/// 3. the facts panel — how long it takes and what is left on it
/// 4. below the tear line — what it costs, and the button that takes the seat
///
/// The zones are separated by surface and rule rather than by whitespace: a
/// rider scanning a feed of departures should be able to jump straight to the
/// one line they care about.
class HomeUpcomingTripCard extends StatelessWidget {
  const HomeUpcomingTripCard({
    super.key,
    required this.trip,
    required this.onBook,
  });

  final UpcomingTripData trip;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    // A departure the rider already holds a seat on is outlined in its booking
    // status colour, so they spot it in the feed before they read a word.
    final borderColor = trip.isBooked
        ? trip.bookedStatus!.accent.withAlpha(80)
        : ClientColors.borderFor(context);

    return PressableScale(
      onTap: trip.isSoldOut ? null : onBook,
      scale: 0.99,
      child: Container(
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.lg),
          border: Border.all(color: borderColor),
          boxShadow: ClientElevation.sm(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeTripCardHeader(trip: trip),
            Padding(
              padding: const EdgeInsets.all(ClientSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeTripJourney(
                    pickup: trip.pickup,
                    destination: trip.destination,
                  ),
                  const SizedBox(height: ClientSpacing.md),
                  HomeTripFacts(trip: trip),
                ],
              ),
            ),
            const TicketTearLine(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                ClientSpacing.xs,
                ClientSpacing.md,
                ClientSpacing.md,
              ),
              child: HomeTripCta(trip: trip, onBook: onBook),
            ),
          ],
        ),
      ),
    );
  }
}
