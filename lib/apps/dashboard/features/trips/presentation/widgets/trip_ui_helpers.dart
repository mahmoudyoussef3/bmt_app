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
