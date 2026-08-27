import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The two clocks a rider reads at a station: when the bus is expected to pull
/// in, and when it is expected to pull away.
///
/// Both are **estimates**, and both are derived rather than stored: a station
/// carries an `"HH:MM"` offset from the route's start, so its clock is a
/// trip's own departure plus that offset. That is why the reference departure
/// travels down here — one route serves every departure on its timetable, and
/// the times shown are only true of the one they were computed from.
///
/// When no departure clock is published, the labels degrade to "35m after
/// departure" rather than disappearing: a rider can still tell a station four
/// minutes in from one ninety minutes in.
class StopScheduleLabels {
  const StopScheduleLabels({required this.arrival, required this.departure});

  /// Builds the labels for [point] against [referenceDeparture], the raw
  /// `HH:mm[:ss]` departure of the trip the estimate is based on.
  factory StopScheduleLabels.of(
    BuildContext context,
    RoutePointData point, {
    required String referenceDeparture,
    required bool isFirst,
    required bool isLast,
  }) {
    String label(String offset) {
      final clock = formatStopClock(context, referenceDeparture, offset);
      if (clock.isNotEmpty) return clock;
      final relative = formatStopOffsetDuration(context, offset);
      return relative.isEmpty
          ? ''
          : context.l10n.booking_stopAfterDeparture(relative);
    }

    final arrival = label(point.arrivalOffset);
    final departure = label(point.departureOffset);

    // The origin has nothing to arrive from and the destination nothing to
    // leave for, so each shows the one clock that means something there.
    final shownArrival = isFirst ? '' : arrival;

    return StopScheduleLabels(
      arrival: shownArrival,
      // A station the bus does not wait at repeats one clock twice; showing it
      // once says the same thing without implying a dwell that is not there.
      // Measured against the arrival actually *shown*, so the origin — whose
      // arrival is suppressed — still prints the departure that matters most
      // on the whole page.
      departure: isLast || departure == shownArrival ? '' : departure,
    );
  }

  final String arrival;
  final String departure;

  bool get isEmpty => arrival.isEmpty && departure.isEmpty;
}

/// The departure a route's station clocks are computed from: the soonest one
/// on its timetable.
///
/// A route has many departures and one set of station offsets, so a clock at a
/// station is only true of the departure it was derived from. Picking the
/// soonest — rather than whichever row Postgres returned first — makes the
/// choice a rider can predict, and it is the departure they are most likely to
/// be reading the page for.
///
/// Empty when nothing on the timetable carries a usable clock.
String referenceDepartureOf(List<RouteTripOptionData> trips) {
  String? earliest;
  var earliestKey = '';

  for (final trip in trips) {
    final minutes = _clockMinutes(trip.departureTime);
    if (minutes == null) continue;
    // Date first, then time: an 06:00 run tomorrow must not outrank a 22:00
    // run tonight.
    final key = '${trip.tripDate}#${minutes.toString().padLeft(4, '0')}';
    if (earliest == null || key.compareTo(earliestKey) < 0) {
      earliest = trip.departureTime;
      earliestKey = key;
    }
  }

  return earliest ?? '';
}

/// Minutes past midnight for a raw `HH:mm[:ss]` clock, or null when the string
/// is not one.
int? _clockMinutes(String rawTime) {
  final parts = rawTime.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

/// One estimated clock, as a quiet icon-and-text pair.
///
/// Deliberately not a filled chip: the station name is what a rider scans for,
/// and a row of tinted time pills down the timeline would outrank it.
class StopTimeLabel extends StatelessWidget {
  const StopTimeLabel({
    super.key,
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;

  /// Used for the clock that matters most at this station — the departure at
  /// the origin, the arrival at the destination.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? ClientColors.textPrimaryFor(context)
        : ClientColors.textSecondaryFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
