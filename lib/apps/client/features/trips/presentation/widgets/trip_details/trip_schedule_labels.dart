import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// Supabase hands a trip its raw `yyyy-MM-dd` / `HH:mm:ss` strings, which are
/// what Trip Details used to print ("2026-07-06", "04:00:00"). Riders read
/// "Mon, Jul 6" and "4:00 AM", so every trip-details card goes through these.
///
/// The raw value is kept as the fallback: a trip missing a date is still
/// better shown as-is than as a blank gap.

String tripDayLabel(BuildContext context, TripData trip) {
  final day = formatTripDay(context, trip.dateLabel);
  return day.isEmpty ? trip.dateLabel : day;
}

String tripTimeLabel(BuildContext context, TripData trip) {
  final time = formatTripTime(context, trip.timeLabel);
  return time.isEmpty ? trip.timeLabel : time;
}

/// "Mon, Jul 6 · 4:00 AM" — the full departure moment, for the boarding pass.
String tripDepartureLabel(BuildContext context, TripData trip) {
  final day = tripDayLabel(context, trip);
  final time = tripTimeLabel(context, trip);
  if (day.isEmpty) return time;
  if (time.isEmpty) return day;
  return '$day · $time';
}
