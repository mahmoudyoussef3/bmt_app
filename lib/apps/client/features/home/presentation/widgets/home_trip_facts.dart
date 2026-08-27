import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_chip.dart';

/// The facts a rider weighs before committing: how long the ride takes, and how
/// many seats are still open.
///
/// Plain captions, the way every other client card states its meta line — two
/// tinted chips side by side turned the bottom of the card into a toolbar and
/// spent colour on a duration nobody is anxious about. The colour is kept for
/// the one fact that changes a decision: a departure down to its last seats, or
/// one with none left, is called out as a pill, and on that card nothing else on
/// the row competes with it.
///
/// A trip the office has not timed drops the ride-time entirely rather than
/// printing "Not set" — an empty fact is not a fact.
class HomeTripFacts extends StatelessWidget {
  const HomeTripFacts({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = ClientColors.textSecondaryFor(context);
    final style = ClientTypography.bodySmall(context).copyWith(color: muted);
    final scarce = trip.isSoldOut || trip.hasScarceSeats;

    return Row(
      children: [
        if (trip.duration.isNotEmpty) ...[
          Icon(Icons.schedule_rounded, size: 15, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              trip.duration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: ClientSpacing.md),
        ],
        if (scarce)
          Flexible(
            child: HomeTripChip(
              icon: Icons.event_seat_rounded,
              label: trip.isSoldOut
                  ? l10n.common_soldOut
                  : l10n.home_seatsOnlyLeft(trip.seatsLeft),
              color: trip.isSoldOut
                  ? ClientColors.journeyRedFor(context)
                  : ClientColors.journeyAmberFor(context),
            ),
          )
        else ...[
          Icon(Icons.event_seat_rounded, size: 15, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.home_seatsAvailable(trip.seatsLeft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}
