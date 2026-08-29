import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_chip.dart';

/// Who runs this departure and how long it takes, as one quiet line parked in
/// the gap the journey rail already crosses.
///
/// Both facts are qualifiers rather than decisions — a rider picks a departure
/// by time, price and seats, then checks who is driving it — so they are set in
/// the meta type every other client card uses for its second line, and they
/// cost the card no row of its own.
///
/// A trip with neither an operator nor a ride time returns nothing at all: an
/// empty fact is not a fact, and the rail closes up around it.
class HomeTripFacts extends StatelessWidget {
  const HomeTripFacts({super.key, required this.trip});

  final UpcomingTripData trip;

  /// Whether this line has anything to say — the card asks before it hands the
  /// rail a slot to draw.
  static bool hasContent(UpcomingTripData trip) =>
      trip.officeName.isNotEmpty || trip.duration.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);
    final style = ClientTypography.bodySmall(context).copyWith(color: muted);

    return Row(
      children: [
        if (trip.officeName.isNotEmpty) ...[
          Icon(Icons.directions_bus_filled_rounded, size: 14, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              trip.officeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
        if (trip.officeName.isNotEmpty && trip.duration.isNotEmpty)
          Text('  ·  ', style: style),
        if (trip.duration.isNotEmpty) ...[
          Icon(Icons.schedule_rounded, size: 14, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              trip.duration,
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

/// What is left on this departure, on the trailing edge of the card's top line.
///
/// The colour is spent on the one fact that changes a decision: a departure
/// down to its last seats, or one with none left, is called out as a pill. A
/// board with room on it says so in plain meta type — a tinted chip on every
/// card would be a toolbar, and a rider would stop reading it.
class HomeTripSeats extends StatelessWidget {
  const HomeTripSeats({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (trip.isSoldOut || trip.hasScarceSeats) {
      return HomeTripChip(
        icon: Icons.event_seat_rounded,
        label: trip.isSoldOut
            ? l10n.common_soldOut
            : l10n.home_seatsOnlyLeft(trip.seatsLeft),
        color: trip.isSoldOut
            ? ClientColors.journeyRedFor(context)
            : ClientColors.journeyAmberFor(context),
      );
    }

    final muted = ClientColors.textSecondaryFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_seat_rounded, size: 14, color: muted),
        const SizedBox(width: ClientSpacing.xxs + 2),
        Flexible(
          child: Text(
            l10n.home_seatsAvailable(trip.seatsLeft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(context).copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
