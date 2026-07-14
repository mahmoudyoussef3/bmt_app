import 'package:flutter/material.dart';

/// Supabase hands trips a raw `yyyy-MM-dd` date and an `HH:mm:ss` time. Riders
/// need "Today · 8:30 AM", so the formatting lives here rather than in a card.

/// Day label for a [DateTime]: Today, Tomorrow, or a short localized date.
String formatCalendarDay(BuildContext context, DateTime date) {
  final daysAway = DateUtils.dateOnly(
    date,
  ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  if (daysAway == 0) return 'Today';
  if (daysAway == 1) return 'Tomorrow';
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

/// How long the ride takes, as "1h 19m", between two raw `HH:mm:ss` times.
/// An arrival earlier than the departure is read as crossing midnight rather
/// than as a negative ride.
String formatTripDuration(String rawDeparture, String rawArrival) {
  final from = _parseClock(rawDeparture);
  final to = _parseClock(rawArrival);
  if (from == null || to == null) return '';

  var minutes =
      (to.hour * 60 + to.minute) - (from.hour * 60 + from.minute);
  if (minutes < 0) minutes += Duration.minutesPerDay;
  if (minutes == 0) return '';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

TimeOfDay? _parseClock(String rawTime) {
  final parts = rawTime.split(':');
  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
