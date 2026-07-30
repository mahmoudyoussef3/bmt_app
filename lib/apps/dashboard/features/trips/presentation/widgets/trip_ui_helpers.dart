import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

/// Status → accent color shared by every trip surface (list rows, grouped
/// sections, timeline nodes, and the details dialog header).
Color tripStatusColor(BuildContext context, OperationTripStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    OperationTripStatus.scheduled => scheme.secondary,
    OperationTripStatus.openForBooking => scheme.primary,
    OperationTripStatus.boarding => scheme.tertiary,
    OperationTripStatus.inProgress => Colors.green,
    OperationTripStatus.completed => Colors.teal,
    OperationTripStatus.cancelled => scheme.error,
  };
}

/// Seat state → tile fill, shared by the cabin seat map and its legend so a
/// colour never means two different things on the same screen.
Color tripSeatColor(BuildContext context, TripSeatState state) {
  final scheme = Theme.of(context).colorScheme;
  return switch (state) {
    TripSeatState.available => scheme.primaryContainer,
    TripSeatState.reserved => scheme.secondaryContainer,
    TripSeatState.paid => Colors.green.withAlpha(60),
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
    // A translucent green over the card surface, so the surface's own
    // foreground is the one that contrasts in both themes.
    TripSeatState.paid => scheme.onSurface,
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
    TripSeatState.paid => Colors.green,
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
