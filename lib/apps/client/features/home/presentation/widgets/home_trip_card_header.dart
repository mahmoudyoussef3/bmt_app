import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_booking_status_style.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/pulse_dot.dart';

/// The ticket's departure band: a tinted strip carrying when the bus leaves,
/// which route it runs, and the rider's own stake in it.
///
/// Departure time is the headline — it is what a rider scans a rail of tickets
/// for, so it gets the width a leading icon used to take and the route runs
/// under it as the caption. The band is tinted in the booking's status colour
/// once the rider holds a seat, so a card they are already on is recognisable
/// before a word is read.
class HomeTripCardHeader extends StatelessWidget {
  const HomeTripCardHeader({super.key, required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = trip.isBooked
        ? trip.bookedStatus!.accent
        : ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        10,
        ClientSpacing.md,
        10,
      ),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 30 : 16),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Departure(trip: trip)),
              const SizedBox(width: ClientSpacing.sm),
              if (trip.isBooked)
                ClientStatusBadge(
                  status: trip.bookedStatus!.badge,
                  label: trip.bookedStatus!.labelFor(context.l10n),
                  showDot: trip.bookedStatus!.isPulsing,
                )
              else if (trip.isLive)
                const _BoardingBadge(),
            ],
          ),
          const SizedBox(height: 2),
          _Route(trip: trip, accent: accent),
        ],
      ),
    );
  }
}

/// When it leaves: the clock time as the headline, the day beside it as the
/// qualifier a rider only needs once the hour has caught their eye.
class _Departure extends StatelessWidget {
  const _Departure({required this.trip});

  final UpcomingTripData trip;

  @override
  Widget build(BuildContext context) {
    final time = formatTripTime(context, trip.departureTime);
    final day = formatTripDay(context, trip.tripDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            time.isEmpty ? context.l10n.home_departureToBeSet : time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (day.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Which service this is: the route, and the operator running it.
class _Route extends StatelessWidget {
  const _Route({required this.trip, required this.accent});

  final UpcomingTripData trip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          trip.isBooked
              ? trip.bookedStatus!.icon
              : Icons.directions_bus_filled_rounded,
          size: 14,
          color: accent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            trip.officeName.isEmpty
                ? trip.routeName
                : '${trip.routeName} · ${trip.officeName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
      ],
    );
  }
}

class _BoardingBadge extends StatelessWidget {
  const _BoardingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.journeyCyan.withAlpha(28),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(color: ClientColors.journeyCyan, size: 7),
          const SizedBox(width: 6),
          Text(
            context.l10n.home_boarding,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.journeyCyan,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
