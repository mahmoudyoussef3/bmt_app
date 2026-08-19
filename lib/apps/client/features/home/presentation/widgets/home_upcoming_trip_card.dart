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
/// 1. the tinted band — when it leaves, which route it runs, and their stake
///    in it
/// 2. the journey — where it picks them up and drops them off
/// 3. the facts — how long it takes and what is left on it
/// 4. below the tear line — what it costs, and the button that takes the seat
///
/// The card lives in a rail, so it takes the height it is given and pins its
/// zones to it: the journey holds a fixed two-line slot per stop and the facts
/// sit on the floor of the body. Swiping the rail then moves one ticket aside
/// to reveal the next with every line already in the same place — a rider
/// compares departures instead of re-reading layouts.
class HomeUpcomingTripCard extends StatelessWidget {
  const HomeUpcomingTripCard({
    super.key,
    required this.trip,
    required this.onBook,
  });

  final UpcomingTripData trip;
  final VoidCallback onBook;

  /// The tallest a ticket in this rail needs to be: every zone at its worst
  /// case (two-line stop names, and the booked strip when any departure in the
  /// rail carries one), grown with the rider's text size.
  ///
  /// One height for the whole rail rather than per card — cards of different
  /// heights sliding past each other read as a broken list, not a deck.
  static double heightFor(BuildContext context, {required bool anyBooked}) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return (282 + (anyBooked ? 38 : 0)) * scale;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = trip.isBooked
        ? trip.bookedStatus!.accent.withAlpha(90)
        : ClientColors.borderFor(context);

    return PressableScale(
      onTap: trip.isSoldOut ? null : onBook,
      scale: 0.98,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClientSpacing.md,
                  12,
                  ClientSpacing.md,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The card is sized for the worst case — two stop names of
                    // two lines each — so most tickets have slack to spend.
                    // Split above and below the journey rather than pooling it
                    // all into one hole over the facts.
                    const Spacer(flex: 2),
                    HomeTripJourney(
                      pickup: trip.pickup,
                      destination: trip.destination,
                      dense: true,
                    ),
                    const Spacer(flex: 3),
                    HomeTripFacts(trip: trip),
                  ],
                ),
              ),
            ),
            const TicketTearLine(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                0,
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
