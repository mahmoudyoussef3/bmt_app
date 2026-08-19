import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_booked_note.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_chip.dart';

/// The facts a rider weighs before committing: how long the ride takes and how
/// many seats are still open.
///
/// Two chips on the floor of the ticket rather than a boxed table — in a rail,
/// the panel that reads as structure on a full-width card reads as clutter, and
/// the seat count carries the only colour so scarcity is the thing the eye
/// catches while swiping. They sit at the same height on every card, so the
/// numbers can be compared without re-reading the layout.
class HomeTripFacts extends StatelessWidget {
  const HomeTripFacts({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: HomeTripChip(
                icon: Icons.schedule_rounded,
                label: trip.duration.isEmpty
                    ? l10n.common_notSet
                    : trip.duration,
                color: ClientColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: HomeTripChip(
                icon: Icons.event_seat_rounded,
                label: _seatLabel(trip, l10n),
                color: _seatColor(context, trip),
              ),
            ),
          ],
        ),
        if (trip.isBooked) ...[
          const SizedBox(height: 8),
          HomeTripBookedNote(trip: trip),
        ],
      ],
    );
  }
}

Color _seatColor(BuildContext context, UpcomingTripData trip) {
  if (trip.isSoldOut) return ClientColors.journeyRedFor(context);
  return trip.hasScarceSeats
      ? ClientColors.journeyAmberFor(context)
      : ClientColors.journeyCyanFor(context);
}

String _seatLabel(UpcomingTripData trip, AppLocalizations l10n) {
  if (trip.isSoldOut) return l10n.common_soldOut;
  if (trip.hasScarceSeats) return l10n.home_seatsOnlyLeft(trip.seatsLeft);
  return l10n.home_seatsAvailable(trip.seatsLeft);
}
