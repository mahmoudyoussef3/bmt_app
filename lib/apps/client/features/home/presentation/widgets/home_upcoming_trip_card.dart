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

/// One bookable departure, laid out as a boarding pass a rider reads in the
/// order they decide in:
///
/// 1. their own stake in it, if any — a seat already held, a bus already at the
///    kerb
/// 2. when it leaves, and who is running it
/// 3. where it picks them up and drops them off
/// 4. how long it takes and what is left on it
/// 5. below the tear line — what it costs, and the button that takes the seat
///
/// It is the same boarding pass [HomeBookingCard] prints for a seat the rider
/// already holds: full width, one card per row, the same status strip, the same
/// journey rail, the same tear line and full-width action. The two used to be
/// different objects — a wide card for a held seat, a narrow fixed-height
/// ticket in a side-scrolling rail for a bookable one — which left the part of
/// Home that actually sells a seat looking like it came from another app.
///
/// The card takes the height its content needs. The rail's fixed height forced
/// every zone to be padded out to a worst case that most departures never hit,
/// so a card with short stop names carried two holes of dead air; here a short
/// departure is simply a shorter card.
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
    // A departure the rider holds a seat on is outlined in that booking's
    // colour, so it is picked out of the column before a word is read.
    final borderColor = trip.isBooked
        ? trip.bookedStatus!.accent.withAlpha(90)
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
