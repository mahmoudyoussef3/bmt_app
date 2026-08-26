import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_fact_line.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// One departure on the timetable: when it leaves, when it arrives, how long
/// it takes, and what is left on it.
///
/// The two clocks are laid out as **separate widgets around a directional
/// arrow**, never as one `'$departure - $arrival'` string. A single string is
/// one bidi paragraph, so a pair of Latin-digit clocks inside an Arabic screen
/// resolves left-to-right and prints the arrival first — which is how this row
/// came to read `20:06 - 19:00` for a trip that departs at 19:00.
class RouteDepartureTile extends StatelessWidget {
  const RouteDepartureTile({
    super.key,
    required this.trip,
    required this.showDivider,
  });

  final RouteTripOptionData trip;

  /// Hairline under the row. Rows are flat and separated by a rule rather than
  /// each being its own tinted panel — a timetable is a list, not a stack of
  /// cards.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final departure = formatTripTime(context, trip.departureTime);
    final arrival = formatTripTime(context, trip.arrivalTime);
    final duration = formatTripDuration(
      context,
      trip.departureTime,
      trip.arrivalTime,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClockLine(departure: departure, arrival: arrival),
                    const SizedBox(height: 6),
                    _MetaLine(trip: trip),
                  ],
                ),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(width: 12),
                _DurationPill(label: duration),
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: ClientColors.borderFor(context)),
      ],
    );
  }
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({required this.departure, required this.arrival});

  final String departure;
  final String arrival;

  @override
  Widget build(BuildContext context) {
    final style = ClientTypography.headingSmall(
      context,
    ).copyWith(fontSize: 16, fontWeight: FontWeight.w800);

    if (departure.isEmpty) {
      return Text(context.l10n.home_departureToBeSet, style: style);
    }

    return Row(
      children: [
        Text(departure, style: style),
        if (arrival.isNotEmpty) ...[
          const SizedBox(width: 8),
          DirectionalIcon(
            Icons.arrow_forward_rounded,
            size: 15,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(width: 8),
          Text(
            arrival,
            style: style.copyWith(
              fontWeight: FontWeight.w700,
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Day, bus type and remaining seats — the facts that are true of the
/// departure itself. What it costs is not one of them: that depends on the
/// stops the rider has yet to choose.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.trip});

  final RouteTripOptionData trip;

  @override
  Widget build(BuildContext context) {
    return RouteFactLine(
      facts: [
        formatTripDay(context, trip.tripDate),
        trip.vehicleType,
        context.l10n.booking_seatsAvailableCount(trip.availableSeats),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timelapse_rounded,
          size: 14,
          color: ClientColors.textTertiaryFor(context),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}
