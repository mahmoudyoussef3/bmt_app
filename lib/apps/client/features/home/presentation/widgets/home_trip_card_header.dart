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
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';

/// The top of a departure card: the rider's own stake in this trip if they have
/// one, then when it leaves and who is running it.
///
/// The stake is a strip across the very top and is drawn *only* when there is
/// one — a seat already held, or a bus already boarding. A board where every
/// card wears a tinted band says nothing; a board where two cards do says
/// exactly which two are the rider's business.
///
/// Below it the departure time is stamped into a tinted block on the leading
/// edge, at one width for every card. That is what a rider scans a column of
/// departures for, so the hours line up under each other and the eye runs down
/// them instead of hunting for the time inside each card's prose.
class HomeTripCardHeader extends StatelessWidget {
  const HomeTripCardHeader({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final time = formatTripTime(context, trip.departureTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trip.isBooked || trip.isLive) _StatusStrip(trip: trip),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ClientSpacing.md,
            ClientSpacing.md,
            ClientSpacing.md,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DepartureStamp(trip: trip, time: time),
              const SizedBox(width: ClientSpacing.sm),
              Expanded(
                child: _Service(trip: trip, hasTime: time.isNotEmpty),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The rider's stake in this departure, across the top of the card: the seats
/// they already hold and where that booking stands, or — on a trip they have
/// not booked — that this bus is boarding right now.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booked = trip.bookedStatus;
    final accent = booked?.accent ?? ClientColors.journeyCyanFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClientSpacing.md,
        vertical: 9,
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
                const SizedBox(width: ClientSpacing.sm),
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

/// When the bus leaves, stamped like the time on a ticket.
///
/// Fixed width so every stamp on the board is the same object in the same
/// place, and the clock is shrunk to fit rather than ellipsised — a departure
/// time with its minutes cut off is worse than a departure time set one point
/// smaller.
class _DepartureStamp extends StatelessWidget {
  const _DepartureStamp({required this.trip, required this.time});

  final UpcomingTripData trip;

  /// The already-formatted clock label; empty when the office has not set one.
  final String time;

  static const double _width = 78;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = trip.isBooked
        ? trip.bookedStatus!.accent
        : ClientColors.primaryFor(context);
    final day = formatTripDay(context, trip.tripDate);

    return Container(
      width: _width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 34 : 18),
        borderRadius: BorderRadius.circular(ClientRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (time.isEmpty)
            Icon(Icons.schedule_rounded, size: 22, color: accent)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                maxLines: 1,
                style: ClientTypography.headingSmall(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  height: 1.1,
                ),
              ),
            ),
          if (day.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ClientTypography.labelSmall(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Which service this is: the route it runs, and the operator selling it.
///
/// A departure whose time the office has not published says so here rather than
/// in the stamp — the stamp is one clock wide, and a rider who cannot see when
/// the bus leaves needs a sentence, not a shrunken one.
class _Service extends StatelessWidget {
  const _Service({required this.trip, required this.hasTime});

  final UpcomingTripData trip;
  final bool hasTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trip.routeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        if (trip.officeName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.directions_bus_filled_rounded,
                size: 14,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.officeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ),
            ],
          ),
        ],
        if (!hasTime) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.home_departureToBeSet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(context).copyWith(
              color: ClientColors.journeyAmberFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
