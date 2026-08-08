import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_fact_cell.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_booked_note.dart';

/// The facts a rider weighs before committing: how long the ride takes and how
/// many seats are still open.
///
/// A panel of fixed cells rather than loose chips — the two numbers land in the
/// same place on every card, so a rider scanning the feed compares departures
/// down a column instead of re-reading each card.
class HomeTripFacts extends StatelessWidget {
  const HomeTripFacts({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final border = ClientColors.borderFor(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: HomeFactCell(
                    icon: Icons.schedule_rounded,
                    caption: l10n.home_rideTime,
                    value: trip.duration.isEmpty
                        ? l10n.common_notSet
                        : trip.duration,
                    valueColor: ClientColors.textPrimaryFor(context),
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: border),
                Expanded(
                  child: HomeFactCell(
                    icon: Icons.event_seat_rounded,
                    caption: l10n.common_seats,
                    value: _seatLabel(trip, l10n),
                    valueColor: _seatColor(trip),
                  ),
                ),
              ],
            ),
          ),
          if (trip.isBooked) ...[
            Divider(height: 1, thickness: 1, color: border),
            HomeTripBookedNote(trip: trip),
          ],
        ],
      ),
    );
  }
}

Color _seatColor(UpcomingTripData trip) {
  if (trip.isSoldOut) return ClientColors.journeyRed;
  return trip.hasScarceSeats
      ? ClientColors.journeyAmber
      : ClientColors.journeyCyan;
}

String _seatLabel(UpcomingTripData trip, AppLocalizations l10n) {
  if (trip.isSoldOut) return l10n.common_soldOut;
  if (trip.hasScarceSeats) return l10n.home_seatsOnlyLeft(trip.seatsLeft);
  return l10n.home_seatsAvailable(trip.seatsLeft);
}
