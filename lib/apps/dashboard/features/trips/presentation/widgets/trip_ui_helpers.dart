import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/core/theme/colors.dart';

/// Status → accent color shared by every trip surface (list rows, grouped
/// sections, timeline nodes, and the details dialog header).
///
/// Stages read as one blue ramp, lightest to darkest, in the order a trip
/// actually moves through them — the operator learns "further along = more
/// saturated" once, instead of six unrelated hues each meaning a different
/// stage. `completed` and `cancelled` are the two stages a trip *stops* at
/// rather than moves through, so both step outside the ramp onto neutral
/// grey — including `cancelled`, which deliberately does **not** reuse
/// [ColorScheme.error]: red is reserved for destructive actions and
/// validation elsewhere in the dashboard, and a cancelled trip is a closed
/// record, not an alarm.
Color tripStatusColor(BuildContext context, OperationTripStatus status) {
  final scheme = Theme.of(context).colorScheme;
  final palette = DashboardChartPalette.of(context);
  final blues = palette.sequential;
  return switch (status) {
    OperationTripStatus.scheduled => blues[1],
    OperationTripStatus.openForBooking => blues[2],
    OperationTripStatus.boarding => blues[3],
    OperationTripStatus.inProgress => blues[4],
    OperationTripStatus.completed => palette.neutral,
    OperationTripStatus.cancelled => scheme.onSurfaceVariant,
  };
}

/// Occupancy → accent colour, bucketed the same way the trips analytics
/// bar chart buckets it (empty/low/mid/high/full), so a trip's fill level
/// reads as a signal everywhere it appears — the list row's progress bar
/// included — rather than the bar always being a flat, meaning-free
/// `primary`.
///
/// Bucketed onto [DashboardChartPalette.sequential]: occupancy is one
/// dimension (how full), not five unrelated categories, so it reads as one
/// blue deepening with the ratio rather than a red-to-green traffic light.
Color tripOccupancyColor(BuildContext context, OperationTrip trip) {
  final palette = DashboardChartPalette.of(context);
  final blues = palette.sequential;
  if (trip.capacity == 0 || trip.bookedSeats == 0) return blues[0];
  if (trip.availableSeats == 0) return blues[4];
  final ratio = trip.bookedSeats / trip.capacity;
  if (ratio < 0.5) return blues[1];
  if (ratio < 0.8) return blues[2];
  return blues[3];
}

/// `120` → `"120"`, `120.5` → `"120.5"` — never a trailing `.0` on a whole
/// fare. Shared so a price reads identically on the row card, the trip
/// details header, and the pricing tab.
String formatTripPrice(double value) {
  final intValue = value.round();
  return value == intValue ? '$intValue' : value.toStringAsFixed(2);
}

/// Seat state → tile fill, shared by the cabin seat map and its legend so a
/// colour never means two different things on the same screen.
Color tripSeatColor(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.primaryContainer,
    TripSeatState.reserved => scheme.secondaryContainer,
    // Was `positive.withAlpha(60)` — `positive` is an `onXContainer` ink
    // (deliberately dark, low-chroma, meant to sit as text on its own
    // container), so alpha-blending it toward white washed out to a muddy
    // grey-teal instead of the opaque, saturated fill every sibling state
    // gets. `success.tint` is the actual container this ink was designed to
    // sit on.
    TripSeatState.paid => context.status(AppStatusTone.success).tint,
    TripSeatState.subscription => scheme.tertiaryContainer,
    TripSeatState.blocked => scheme.errorContainer,
  };
}

/// Text and icon colour that stays readable on [tripSeatColor].
Color tripSeatOnColor(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.onPrimaryContainer,
    TripSeatState.reserved => scheme.onSecondaryContainer,
    TripSeatState.paid => context.status(AppStatusTone.success).ink,
    TripSeatState.subscription => scheme.onTertiaryContainer,
    TripSeatState.blocked => scheme.onErrorContainer,
  };
}

/// The saturated edge of [tripSeatColor], used for seat tile borders.
Color tripSeatAccent(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.primary,
    TripSeatState.reserved => scheme.secondary,
    TripSeatState.paid => context.status(AppStatusTone.success).accent,
    TripSeatState.subscription => scheme.tertiary,
    TripSeatState.blocked => scheme.error,
  };
}

/// Relative Arabic date label ("اليوم", "غداً", weekday name, or day/month).
String tripFriendlyDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = day.difference(today).inDays;
  if (difference == 0) return 'اليوم';
  if (difference == 1) return 'غداً';
  if (difference == -1) return 'أمس';
  const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return '${weekdays[date.weekday - 1]}، ${date.day}/${date.month}';
}
