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

/// One bookable departure, as a compact ticket a rider reads in four beats:
///
/// 1. their own stake in it, if any — a seat already held, a bus already at the
///    kerb — on a tinted strip across the top
/// 2. when it leaves, and how much of it is left
/// 3. where it picks them up and drops them off, with the operator and the ride
///    time on the rail between the two stops
/// 4. below the dashed rule — what it costs, and the button that takes the seat
///
/// Deliberately smaller than the boarding pass [HomeBookingCard] prints for a
/// seat the rider already holds, and that is the point: the two cards are not
/// doing the same job. A held seat is one card the rider has stopped on, so it
/// can afford a captioned journey and a full-width action. The departure board
/// is a column of candidates being compared, and a card that spends a third of
/// a phone screen on each one lets a rider see one and a half of them — the
/// comparison the section exists for happens off screen, in memory.
///
/// So every zone here is one row: the clock and the seats share the top line,
/// the operator and the ride time ride inside the journey's own connector gap,
/// and the fare and the CTA share the stub. Nothing was dropped except the
/// route name, which on a card that already names both stops was the same fact
/// said twice.
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
            if (trip.isBooked || trip.isLive) HomeTripStatusStrip(trip: trip),
            Padding(
              padding: const EdgeInsets.all(_padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeTripCardHeader(trip: trip),
                  const SizedBox(height: ClientSpacing.sm),
                  HomeTripJourney(
                    pickup: trip.pickup,
                    destination: trip.destination,
                    dense: true,
                    middle: HomeTripFacts.hasContent(trip)
                        ? HomeTripFacts(trip: trip)
                        : null,
                  ),
                  const SizedBox(height: ClientSpacing.sm),
                  DashedDivider(color: ClientColors.borderFor(context)),
                  const SizedBox(height: ClientSpacing.sm),
                  // The action takes the width its own label needs and the
                  // fare gives way: "Book another seat" is the longest label on
                  // the board, and a button reading "Book another…" is one a
                  // rider has to guess at. Past [_ctaMaxWidthFraction] of the
                  // stub — a phone that narrow, or a rider on very large text —
                  // the label ellipsises rather than pushing the fare off the
                  // card.
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        Expanded(child: HomeTripFare(price: trip.price)),
                        const SizedBox(width: ClientSpacing.sm),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                constraints.maxWidth * _ctaMaxWidthFraction,
                          ),
                          child: HomeTripCta(trip: trip, onBook: onBook),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One gutter for the whole card, a step under the design's 16pt `CARD`
  /// padding — the card is dense by intent and its own edges should be too.
  static const double _padding = 14;

  /// How much of the ticket stub the action may take before its label starts
  /// to ellipsise. What is left is the fare's floor.
  ///
  /// Set so the longest label on the board — "Book another seat", and its
  /// Arabic — still fits whole on the narrowest phone the app ships to. It only
  /// binds on a rider running very large text, where a fare pushed off the card
  /// would be the worse loss.
  static const double _ctaMaxWidthFraction = 0.7;
}
