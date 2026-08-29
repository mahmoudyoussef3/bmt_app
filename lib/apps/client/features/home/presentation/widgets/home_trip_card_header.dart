import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_booked_note.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_trip_facts.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';

/// The top line of a departure card: when the bus leaves on the leading edge,
/// how much of it is left on the trailing one.
///
/// One row, not the tinted stamp block this used to be. The stamp gave the
/// clock a fixed 78pt column and a second line for the day, which bought
/// alignment down the board at the cost of the tallest zone on the card; a
/// plain strong clock at the start of the row lines up just as well, because
/// every card starts its row in the same place.
///
/// Both halves flex: a departure with no published time says so in words here,
/// and that sentence is longer than any clock.
class HomeTripCardHeader extends StatelessWidget {
  const HomeTripCardHeader({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: _Departure(trip: trip)),
        const SizedBox(width: ClientSpacing.sm),
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: HomeTripSeats(trip: trip),
          ),
        ),
      ],
    );
  }
}

/// When the bus leaves: the clock, then the day it runs.
///
/// A departure whose time the office has not published prints that instead of
/// the clock — a rider who cannot see when the bus leaves needs the sentence,
/// and it is the one fact on the card worth colouring amber.
class _Departure extends StatelessWidget {
  const _Departure({required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final time = formatTripTime(context, trip.departureTime);
    final day = formatTripDay(context, trip.tripDate);

    if (time.isEmpty) {
      return Text(
        context.l10n.home_departureToBeSet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ClientTypography.labelLarge(context).copyWith(
          color: ClientColors.journeyAmberFor(context),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (day.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ],
    );
  }
}

/// The rider's stake in this departure, across the top of the card: the seats
/// they already hold and where that booking stands, or — on a trip they have
/// not booked — that this bus is boarding right now.
///
/// Drawn *only* when there is a stake. A board where every card wears a tinted
/// band says nothing; a board where two cards do says exactly which two are the
/// rider's business.
class HomeTripStatusStrip extends StatelessWidget {
  const HomeTripStatusStrip({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booked = trip.bookedStatus;
    final accent = booked?.accent ?? ClientColors.journeyCyanFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 32 : 18),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
      ),
      child: booked == null
          ? const _BoardingNow()
          : Row(
              children: [
                Expanded(child: HomeTripBookedNote(trip: trip)),
                const SizedBox(width: ClientSpacing.xs),
                ClientStatusBadge(
                  status: booked.badge,
                  label: booked.labelFor(context.l10n),
                  showDot: booked.isPulsing,
                ),
              ],
            ),
    );
  }
}

/// A bus at the kerb with its doors open. Pulsing, because unlike everything
/// else on the card this one expires.
class _BoardingNow extends StatelessWidget {
  const _BoardingNow();

  @override
  Widget build(BuildContext context) {
    final cyan = ClientColors.journeyCyanFor(context);

    return Row(
      children: [
        PulseDot(color: cyan, size: 7),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.l10n.home_boarding,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: cyan, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
