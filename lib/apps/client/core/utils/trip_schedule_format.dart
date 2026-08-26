import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Supabase hands trips a raw `yyyy-MM-dd` date and an `HH:mm:ss` time. Riders
/// need "Today · 8:30 AM", so the formatting lives here rather than in a card.

/// Day label for a [DateTime]: Today, Tomorrow, or a short localized date.
String formatCalendarDay(BuildContext context, DateTime date) {
  final daysAway = DateUtils.dateOnly(
    date,
  ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  if (daysAway == 0) return context.l10n.common_today;
  if (daysAway == 1) return context.l10n.common_tomorrow;
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

/// Day label for an ISO `yyyy-MM-dd` date: Today, Tomorrow, or a short date.
/// Empty when the trip carries no usable date.
String formatTripDay(BuildContext context, String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  return formatCalendarDay(context, date);
}

/// Clock label for a raw `HH:mm:ss` time, in the reader's 12/24-hour format.
/// Empty when the dashboard has not set a departure time on the trip.
String formatTripTime(BuildContext context, String rawTime) {
  final clock = _parseClock(rawTime);
  if (clock == null) return '';

  return MaterialLocalizations.of(context).formatTimeOfDay(
    clock,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Clock label for a stop that sits [offset] into the trip.
///
/// A stop's `arrival_offset` / `departure_offset` is an `"HH:MM"` **duration
/// measured from the route's start**, not a time of day — the contract
/// `parse_route_offset` states in the database. So the clock a rider reads is
/// the trip's own departure plus that duration, wrapping past midnight on a
/// long overnight run.
///
/// Empty when either half is missing: a stop the operator never timed is shown
/// without a time rather than with the departure time repeated at it.
String formatStopClock(
  BuildContext context,
  String rawDeparture,
  String offset,
) {
  final departure = _parseClock(rawDeparture);
  final minutes = _parseOffsetMinutes(offset);
  if (departure == null || minutes == null) return '';

  final total =
      (departure.hour * 60 + departure.minute + minutes) %
      Duration.minutesPerDay;
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: total ~/ 60, minute: total % 60),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// An `"HH:MM"` duration as whole minutes. Null — not zero — when the string is
/// not one, so a missing offset stays distinguishable from a stop the bus
/// reaches at the moment it departs.
int? _parseOffsetMinutes(String offset) {
  final parts = offset.trim().split(':');
  if (parts.length < 2) return null;

  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  if (hours == null || minutes == null || hours < 0 || minutes < 0) return null;
  if (minutes > 59) return null;
  return hours * 60 + minutes;
}

/// How long the ride takes, as "1h 19m", between two raw `HH:mm:ss` times.
/// An arrival earlier than the departure is read as crossing midnight rather
/// than as a negative ride.
String formatTripDuration(
  BuildContext context,
  String rawDeparture,
  String rawArrival,
) {
  final from = _parseClock(rawDeparture);
  final to = _parseClock(rawArrival);
  if (from == null || to == null) return '';

  var minutes = (to.hour * 60 + to.minute) - (from.hour * 60 + from.minute);
  if (minutes < 0) minutes += Duration.minutesPerDay;
  if (minutes == 0) return '';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final l10n = context.l10n;
  if (hours == 0) return l10n.common_durationMinutes(rest);
  if (rest == 0) return l10n.common_durationHours(hours);
  return l10n.common_durationHoursMinutes(hours, rest);
}

TimeOfDay? _parseClock(String rawTime) {
  final parts = rawTime.split(':');
  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
